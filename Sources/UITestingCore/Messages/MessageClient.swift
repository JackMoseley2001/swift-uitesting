import Foundation
import Network

/// The app's end of the connection to the UI test that launched it.
///
/// The test listens on a port of the loopback interface and passes the port in the
/// launch environment. The app connects to it, receives messages as lines of JSON,
/// and answers each one when its receivers have run.
@MainActor
package final class MessageClient {
    private let port: NWEndpoint.Port
    private let receivers: MessageReceivers
    private var connection: NWConnection?
    private var lines = MessageLines()
    private var isStopped = false

    /// How many attempts in a row have ended without a message being received.
    private var failedAttempts = 0

    /// How many attempts to make before giving up, which is about ten seconds of them.
    ///
    /// The test listens before it launches the app, so the first attempt normally
    /// succeeds. Once the test process has gone there is nothing to connect to, and an
    /// app that is left running should not keep trying.
    private static let maximumFailedAttempts = 40

    package init?(port: UInt16, receivers: MessageReceivers) {
        guard let port = NWEndpoint.Port(rawValue: port) else { return nil }
        self.port = port
        self.receivers = receivers
    }

    /// Connects, and tries again for a while if the connection is lost.
    package func start() {
        guard connection == nil, !isStopped, failedAttempts < Self.maximumFailedAttempts else { return }
        let connection = NWConnection(host: .ipv4(.loopback), port: port, using: .tcp)
        self.connection = connection
        lines = MessageLines()
        connection.stateUpdateHandler = { [weak self] state in
            MainActor.assumeIsolated {
                switch state {
                case .failed, .waiting, .cancelled: self?.reconnect(after: connection)
                default: break
                }
            }
        }
        connection.start(queue: .main)
        receive(on: connection)
    }

    package func stop() {
        isStopped = true
        connection?.cancel()
        connection = nil
    }

    private func receive(on connection: NWConnection) {
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 1 << 16
        ) { [weak self] data, _, isComplete, error in
            MainActor.assumeIsolated {
                guard let self, self.connection === connection else { return }
                for line in self.lines.append(data ?? Data()) {
                    self.failedAttempts = 0
                    self.handle(line, on: connection)
                }
                if isComplete || error != nil {
                    self.reconnect(after: connection)
                } else {
                    self.receive(on: connection)
                }
            }
        }
    }

    private func handle(_ line: Data, on connection: NWConnection) {
        guard let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: line) else { return }
        Task {
            let reply = await receivers.handle(envelope)
            guard let data = try? MessageLines.line(reply) else { return }
            connection.send(content: data, completion: .contentProcessed { _ in })
        }
    }

    private func reconnect(after connection: NWConnection) {
        guard self.connection === connection else { return }
        connection.cancel()
        self.connection = nil
        failedAttempts += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            MainActor.assumeIsolated { self?.start() }
        }
    }
}
