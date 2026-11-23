import Foundation
import Testing

@testable import UITesting
@testable import UITestingCore

private struct ExpireSession: UITestMessage, Equatable {}

private struct RenameUser: UITestMessage, Equatable {
    var name: String
}

private func envelope(_ message: some UITestMessage, id: Int = 1) throws -> MessageEnvelope {
    MessageEnvelope(id: id, name: type(of: message).messageName, body: try JSONEncoder().encode(message))
}

@Suite
@MainActor
struct MessageReceiversTests {
    @Test
    func aMessageReachesItsReceiverDecoded() async throws {
        let receivers = MessageReceivers()
        var received: [RenameUser] = []
        _ = receivers.add(RenameUser.self) { received.append($0) }

        let reply = await receivers.handle(try envelope(RenameUser(name: "Grace"), id: 7))

        #Testing::expect(reply == MessageReply(id: 7, outcome: .handled))
        #Testing::expect(received == [RenameUser(name: "Grace")])
    }

    @Test
    func aMessageWithNoReceiverSaysSo() async throws {
        let receivers = MessageReceivers()
        _ = receivers.add(RenameUser.self) { _ in }

        let reply = await receivers.handle(try envelope(ExpireSession()))

        #Testing::expect(reply.outcome == .noReceiver)
    }

    @Test
    func aRemovedReceiverNoLongerReceives() async throws {
        let receivers = MessageReceivers()
        let token = receivers.add(ExpireSession.self) { _ in }
        receivers.remove(token, named: ExpireSession.messageName)

        let reply = await receivers.handle(try envelope(ExpireSession()))

        #Testing::expect(reply.outcome == .noReceiver)
    }

    @Test
    func anErrorFromAReceiverIsPassedBack() async throws {
        let receivers = MessageReceivers()
        _ = receivers.add(ExpireSession.self) { _ in throw TestError(message: "no session") }

        let reply = await receivers.handle(try envelope(ExpireSession()))

        #Testing::expect(reply.outcome == .failed(#"TestError(message: "no session")"#))
    }
}

@Suite
@MainActor
struct MessageSequenceTests {
    @Test
    func aMessageIsAnsweredWhenTheLoopComesBackForTheNext() async throws {
        let receivers = MessageReceivers()
        var received: [String] = []
        let reading = Task {
            let messages = UITestMessageSequence(
                deliveries: UITestMessages.deliveries(of: RenameUser.self, in: receivers)
            )
            for await message in messages {
                await Task.yield()
                received.append(message.name)
            }
        }
        await Task.yield()

        let first = await receivers.handle(try envelope(RenameUser(name: "Grace")))
        #Testing::expect(first.outcome == .handled)
        #Testing::expect(received == ["Grace"])

        let second = await receivers.handle(try envelope(RenameUser(name: "Ada")))
        #Testing::expect(second.outcome == .handled)
        #Testing::expect(received == ["Grace", "Ada"])

        reading.cancel()
        await reading.value
        let afterwards = await receivers.handle(try envelope(RenameUser(name: "Katherine")))
        #Testing::expect(afterwards.outcome == .noReceiver)
        #Testing::expect(received == ["Grace", "Ada"])
    }

    @Test
    func receivingHandlesEachMessageUntilItsTaskIsCancelled() async throws {
        let receivers = MessageReceivers()
        var received: [String] = []
        let receiving = Task {
            for await delivery in UITestMessages.deliveries(of: RenameUser.self, in: receivers) {
                await delivery.finish { received.append($0.name) }
            }
        }
        await Task.yield()

        let reply = await receivers.handle(try envelope(RenameUser(name: "Grace")))
        #Testing::expect(reply.outcome == .handled)
        #Testing::expect(received == ["Grace"])

        receiving.cancel()
        await receiving.value
        let afterwards = await receivers.handle(try envelope(RenameUser(name: "Ada")))
        #Testing::expect(afterwards.outcome == .noReceiver)
    }

    @Test
    func anErrorWhileHandlingADeliveryIsPassedBack() async throws {
        let receivers = MessageReceivers()
        let reading = Task {
            for await delivery in UITestMessages.deliveries(of: ExpireSession.self, in: receivers) {
                await delivery.finish { _ in throw TestError(message: "no session") }
            }
        }
        await Task.yield()

        let reply = await receivers.handle(try envelope(ExpireSession()))

        #Testing::expect(reply.outcome == .failed(#"TestError(message: "no session")"#))
        reading.cancel()
    }
}

/// These use the host that tests share, so they run one at a time and close it after them.
@Suite(.serialized)
struct MessageChannelTraitTests {
    @Test
    func theTraitTellsTheAppWhereToConnect() throws {
        defer { MessageHost.shared.stop() }
        let launch = try LaunchConfiguration(applying: [.messageChannel])

        let port = try #Testing::require(launch.environment["UITESTING_MESSAGE_PORT"].flatMap(UInt16.init))
        #Testing::expect(port != 0)
        #Testing::expect(LaunchTraits(environment: launch.environment).messagePort == port)
    }

    @Test
    func traitsOfOneTestShareAChannel() throws {
        defer { MessageHost.shared.stop() }
        // A suite and one of its tests can both have the trait.
        let launch = try LaunchConfiguration(applying: [.messageChannel, .messageChannel])
        let relaunch = try launch.applying([.messageChannel])

        #Testing::expect(launch.environment == relaunch.environment)
    }

    @Test
    func theChannelIsClosedAndOpenedAgainForTheNextTest() throws {
        defer { MessageHost.shared.stop() }
        _ = try LaunchConfiguration(applying: [.messageChannel])
        #Testing::expect(MessageHost.shared.port != nil)

        MessageHost.shared.stop()
        #Testing::expect(MessageHost.shared.port == nil)

        let next = try LaunchConfiguration(applying: [.messageChannel])
        #Testing::expect(next.environment["UITESTING_MESSAGE_PORT"] == MessageHost.shared.port.map(String.init))
    }

    @Test
    func anAppThatWasNotGivenAChannelHasNoPort() {
        #Testing::expect(LaunchTraits().messagePort == nil)
    }
}

@Suite
struct MessageLinesTests {
    @Test
    func linesAreReturnedOnceTheyAreComplete() {
        var lines = MessageLines()

        #Testing::expect(lines.append(Data("{\"a\"".utf8)) == [])
        #Testing::expect(
            lines.append(Data(":1}\n{\"b\":2}\n{\"c\"".utf8)) == [Data("{\"a\":1}".utf8), Data("{\"b\":2}".utf8)]
        )
        #Testing::expect(lines.append(Data(":3}\n".utf8)) == [Data("{\"c\":3}".utf8)])
    }
}

@Suite
struct MessageSendTests {
    /// Polling that never sleeps, with a clock that moves on one second at each check of the time.
    private func polling() -> ExpectationPolling {
        var now = ContinuousClock.now
        return ExpectationPolling(
            interval: .seconds(1),
            now: { now += .seconds(1); return now },
            sleep: { _ in },
            betweenEvaluations: {}
        )
    }

    private func failure(isListening: Bool = true, attempts: [MessageAttempt]) -> (failure: String?, sent: Int) {
        var sent = 0
        let failure = MessageSend.failure(
            message: "ExpireSession",
            timeout: .seconds(5),
            isListening: isListening,
            polling: polling(),
            attempt: { _ in
                defer { sent += 1 }
                return attempts[min(sent, attempts.count - 1)]
            }
        )
        return (failure, sent)
    }

    @Test
    func aHandledMessagePasses() {
        #Testing::expect(failure(attempts: [.handled]) == (nil, 1))
    }

    @Test
    func waitsForTheAppToConnectAndToHaveAReceiver() {
        #Testing::expect(failure(attempts: [.noConnection, .noConnection, .noReceiver, .handled]) == (nil, 4))
    }

    @Test
    func aMessageThatReachedTheAppIsNotSentAgain() {
        let failed = failure(attempts: [.failed("no session"), .handled])
        #Testing::expect(failed == ("The app failed to handle ExpireSession: no session", 1))

        let unanswered = failure(attempts: [.noReply, .handled])
        #Testing::expect(
            unanswered == ("Could not send ExpireSession: the app did not finish handling it within 5 seconds", 1)
        )
    }

    @Test
    func givesUpOnAnAppThatNeverConnects() {
        #Testing::expect(
            failure(attempts: [.noConnection]).failure == """
                Could not send ExpireSession: the app did not connect within 5 seconds. \
                Is it running, and does it receive a message with onUITestMessage or UITestMessages?
                """
        )
    }

    @Test
    func givesUpOnAnAppWithNoReceiver() {
        #Testing::expect(
            failure(attempts: [.noReceiver]).failure
                == "Could not send ExpireSession: nothing in the app was receiving this message after 5 seconds"
        )
    }

    @Test
    func aTestWithoutTheTraitIsToldToAddIt() {
        #Testing::expect(
            failure(isListening: false, attempts: [.handled])
                == ("Could not send ExpireSession: the test does not have the messageChannel trait", 0)
        )
    }
}

/// Runs both ends in this process, over a real connection.
@Suite(.serialized)
struct MessageConnectionTests {
    private func send(_ message: some UITestMessage, from host: MessageHost) async throws -> MessageAttempt {
        let body = try JSONEncoder().encode(message)
        let name = type(of: message).messageName
        // The wait blocks its thread, as it does in a UI test, so it is kept off the main actor.
        return await Task.detached {
            var attempt = MessageAttempt.noConnection
            for _ in 0..<50 where attempt == .noConnection {
                attempt = host.send(name, body: body, replyWithin: .seconds(5))
                if attempt == .noConnection { try? await Task.sleep(for: .milliseconds(100)) }
            }
            return attempt
        }.value
    }

    @Test
    func aMessageCrossesTheConnectionAndIsAnswered() async throws {
        let host = MessageHost()
        let port = try host.start()
        let received = await MainActor.run { Received() }
        let client = await MainActor.run {
            let receivers = MessageReceivers()
            _ = receivers.add(RenameUser.self) { received.names.append($0.name) }
            let client = MessageClient(port: port, receivers: receivers)
            client?.start()
            return client
        }

        #Testing::expect(try await send(RenameUser(name: "Grace"), from: host) == .handled)
        #Testing::expect(try await send(RenameUser(name: "Ada"), from: host) == .handled)
        #Testing::expect(try await send(ExpireSession(), from: host) == .noReceiver)
        #Testing::expect(await received.names == ["Grace", "Ada"])

        await client?.stop()
        host.stop()
    }

    @Test
    func aStoppedHostHasNoAppAndCanBeStartedAgain() async throws {
        let host = MessageHost()
        let port = try host.start()
        let client = await MainActor.run {
            let receivers = MessageReceivers()
            _ = receivers.add(ExpireSession.self) { _ in }
            let client = MessageClient(port: port, receivers: receivers)
            client?.start()
            return client
        }
        #Testing::expect(try await send(ExpireSession(), from: host) == .handled)

        host.stop()
        await client?.stop()

        #Testing::expect(host.port == nil)
        #Testing::expect(host.send("ExpireSession", body: Data("{}".utf8), replyWithin: .seconds(1)) == .noConnection)

        let restarted = try host.start()
        #Testing::expect(restarted != 0)
        #Testing::expect(host.port == restarted)
        host.stop()
    }

    @Test
    func anAppThatConnectsLaterTakesOver() async throws {
        let host = MessageHost()
        let port = try host.start()
        let received = await MainActor.run { Received() }

        @MainActor func connect(as name: String) -> MessageClient? {
            let receivers = MessageReceivers()
            _ = receivers.add(ExpireSession.self) { _ in received.names.append(name) }
            let client = MessageClient(port: port, receivers: receivers)
            client?.start()
            return client
        }

        let first = await connect(as: "first launch")
        #Testing::expect(try await send(ExpireSession(), from: host) == .handled)
        await first?.stop()

        let second = await connect(as: "second launch")
        #Testing::expect(try await send(ExpireSession(), from: host) == .handled)
        #Testing::expect(await received.names == ["first launch", "second launch"])

        await second?.stop()
        host.stop()
    }
}

@MainActor
private final class Received {
    var names: [String] = []
}
