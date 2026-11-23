import Foundation
import Network

/// The test's end of the connection to the app.
///
/// One host serves the test that is running. It listens on a port of the loopback
/// interface that the system chooses, from when the test's launch is prepared until
/// the test is torn down, and talks to whichever app connected last, so a relaunched
/// app takes over from the one before it.
final class MessageHost: @unchecked Sendable {
    static let shared = MessageHost()

    private let queue = DispatchQueue(label: "UITesting.MessageHost")
    private let condition = NSCondition()
    private var listener: NWListener?
    private var listenerError: NWError?
    private var connection: NWConnection?
    private var isConnected = false
    private var lines = MessageLines()
    private var replies: [Int: MessageReply] = [:]
    private var nextID = 0

    /// The port the host is listening on, or `nil` if it has not been started.
    var port: UInt16? {
        condition.withLock { listener?.port?.rawValue }
    }

    /// Starts listening, if the host is not already, and returns the port.
    func start() throws -> UInt16 {
        if let port { return port }

        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
        let listener = try NWListener(using: parameters)
        listener.stateUpdateHandler = { [self] state in
            condition.withLock {
                if case .failed(let error) = state { listenerError = error }
                condition.broadcast()
            }
        }
        listener.newConnectionHandler = { [self] in accept($0) }
        listener.start(queue: queue)

        let deadline = Date(timeIntervalSinceNow: 5)
        return try condition.withLock {
            while listener.port == nil || listener.port == .any, listenerError == nil {
                guard condition.wait(until: deadline) else { break }
            }
            guard let port = listener.port?.rawValue, port != 0 else {
                listener.cancel()
                throw MessageHostError(reason: listenerError.map { "\($0)" } ?? "it was not ready in time")
            }
            self.listener = listener
            return port
        }
    }

    /// Stops listening and lets go of the app, so that nothing is carried from one test
    /// to the next. Does nothing if the host is not started.
    func stop() {
        let (listener, connection) = condition.withLock {
            defer {
                self.listener = nil
                self.listenerError = nil
                self.connection = nil
                isConnected = false
                lines = MessageLines()
                replies = [:]
                condition.broadcast()
            }
            return (self.listener, self.connection)
        }
        listener?.cancel()
        connection?.cancel()
    }

    /// Sends a message to the app that is connected, and waits for its answer.
    func send(_ name: String, body: Data, replyWithin timeout: Duration) -> MessageAttempt {
        condition.lock()
        guard let connection, isConnected else {
            condition.unlock()
            return .noConnection
        }
        nextID += 1
        let id = nextID
        condition.unlock()

        guard let line = try? MessageLines.line(MessageEnvelope(id: id, name: name, body: body)) else {
            return .failed("the message could not be encoded")
        }
        connection.send(content: line, completion: .contentProcessed { _ in })

        let deadline = Date(timeIntervalSinceNow: timeout.timeInterval)
        return condition.withLock {
            while replies[id] == nil, self.connection === connection {
                guard condition.wait(until: deadline) else { break }
            }
            switch replies.removeValue(forKey: id)?.outcome {
            case .handled: return .handled
            case .noReceiver: return .noReceiver
            case .failed(let reason): return .failed(reason)

            // An app that went away before it answered is one to wait for again,
            // such as across a relaunch.
            case nil: return self.connection === connection ? .noReply : .noConnection
            }
        }
    }

    private func accept(_ connection: NWConnection) {
        let previous = condition.withLock {
            let previous = self.connection
            self.connection = connection
            isConnected = false
            lines = MessageLines()
            return previous
        }
        previous?.cancel()

        connection.stateUpdateHandler = { [self] state in
            condition.withLock {
                guard self.connection === connection else { return }
                switch state {
                case .ready:
                    isConnected = true

                case .failed, .cancelled:
                    self.connection = nil
                    isConnected = false

                default:
                    break
                }
                condition.broadcast()
            }
        }
        connection.start(queue: queue)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 16) { [self] data, _, isComplete, error in
            let goesOn = condition.withLock {
                guard self.connection === connection else { return false }
                for line in lines.append(data ?? Data()) {
                    if let reply = try? JSONDecoder().decode(MessageReply.self, from: line) {
                        replies[reply.id] = reply
                    }
                }
                if isComplete || error != nil {
                    self.connection = nil
                    isConnected = false
                }
                condition.broadcast()
                return self.connection != nil
            }
            if goesOn {
                receive(on: connection)
            } else {
                connection.cancel()
            }
        }
    }
}

/// The test could not start listening for the app.
struct MessageHostError: Error, CustomStringConvertible {
    var reason: String

    var description: String {
        "Could not listen for the app to connect: \(reason)"
    }
}
