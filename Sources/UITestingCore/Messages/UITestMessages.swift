/// Receives the messages that a UI test sends to the app while it is running.
///
/// In SwiftUI, use the `onUITestMessage(_:perform:)` modifier. Anywhere else, read the
/// messages of a type in a task:
///
/// ```swift
/// Task {
///     await UITestMessages.receive(ExpireSession.self) { _ in
///         session.expire()
///     }
/// }
/// ```
///
/// ## The test waits for the app
///
/// The test's `context.send(_:)` returns when the app has finished with the message,
/// so the test can go straight on to check what the app shows. An error thrown while
/// handling a message fails the test.
///
/// ## When nothing is received
///
/// Messages only arrive when a UI test launched the app with the `messageChannel`
/// trait. The connection to the test is made only if ``LaunchTraits/current`` says
/// that a UI test launched the app. It is empty in a release build, so a shipped app
/// never listens for messages. Receiving is safe to leave in the app: without a test,
/// the calls here wait and do nothing.
@MainActor
public enum UITestMessages {
    static let receivers = MessageReceivers()
    private static var client: MessageClient?

    /// Handles each message of one type as it arrives, until the task is cancelled.
    ///
    /// ```swift
    /// let receiving = Task {
    ///     await UITestMessages.receive(RenameUser.self) { message in
    ///         try account.rename(to: message.name)
    ///     }
    /// }
    /// ```
    ///
    /// The call does not return until its task is cancelled. The test that sent a
    /// message carries on when `perform` returns, and fails if `perform` throws.
    ///
    /// - Parameters:
    ///   - type: The type of message to receive.
    ///   - perform: What to do with a message. It runs on the main actor.
    public static func receive<Message: UITestMessage>(
        _ type: Message.Type = Message.self,
        perform: @MainActor (Message) async throws -> Void
    ) async {
        for await delivery in deliveries(of: type) {
            await delivery.finish(handling: perform)
        }
    }

    /// The messages of one type, as a sequence to read for as long as you want them.
    ///
    /// ```swift
    /// for await message in UITestMessages.messages(of: RenameUser.self) {
    ///     account.rename(to: message.name)
    /// }
    /// ```
    ///
    /// The test that sent a message carries on when the loop comes back for the next
    /// one, or ends. Messages stop being received when the task that reads the
    /// sequence is cancelled.
    ///
    /// A loop has no way to tell the test that handling a message failed. Use
    /// ``receive(_:perform:)`` when it can.
    ///
    /// - Parameter type: The type of message to receive.
    public static func messages<Message: UITestMessage>(
        of type: Message.Type = Message.self
    ) -> UITestMessageSequence<Message> {
        UITestMessageSequence(deliveries: deliveries(of: type))
    }

    /// The messages of one type, each with the means to answer the test.
    static func deliveries<Message: UITestMessage>(
        of type: Message.Type,
        in receivers: MessageReceivers = receivers
    ) -> AsyncStream<MessageDelivery<Message>> {
        connectIfAsked()
        return AsyncStream { continuation in
            let token = receivers.add(type) { message in
                try await withCheckedThrowingContinuation { answer in
                    // A delivery that the stream does not keep is let go, which answers the test.
                    continuation.yield(MessageDelivery(message: message, answer: answer))
                }
            }
            continuation.onTermination = { _ in
                Task { @MainActor in receivers.remove(token, named: Message.messageName) }
            }
        }
    }

    /// Connects to the UI test, the first time something asks to receive a message.
    private static func connectIfAsked() {
        let launch = LaunchTraits.current
        guard client == nil, launch.isUITesting, let port = launch.messagePort else { return }
        client = MessageClient(port: port, receivers: receivers)
        client?.start()
    }
}

extension LaunchTraits {
    /// The port on which the UI test that launched the app is waiting for it to connect.
    var messagePort: UInt16? {
        environment[LaunchEnvironmentKey.messagePort].flatMap(UInt16.init)
    }
}

extension LaunchConfiguration {
    /// Tells the app where to connect to receive messages from the test.
    package mutating func setMessagePort(_ port: UInt16) {
        environment[LaunchEnvironmentKey.messagePort] = String(port)
    }
}
