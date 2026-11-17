import Foundation

/// One message on its way to something that reads messages as a sequence, with the
/// means to tell the test how handling it went.
///
/// The test is waiting for an answer, so a delivery always gives one: when it is
/// finished, or, if it never is, when it is let go.
final class MessageDelivery<Message: UITestMessage>: @unchecked Sendable {
    let message: Message

    private let lock = NSLock()
    private var answer: CheckedContinuation<Void, any Error>?
    private var wasTaken = false

    init(message: Message, answer: CheckedContinuation<Void, any Error>) {
        self.message = message
        self.answer = answer
    }

    /// Notes that a reader has the message, so that letting go of it means it was handled.
    func take() {
        lock.withLock { wasTaken = true }
    }

    /// Tells the test how handling the message went. Only the first call counts.
    func finish(_ result: Result<Void, any Error> = .success(())) {
        let answer = lock.withLock {
            defer { self.answer = nil }
            return self.answer
        }
        answer?.resume(with: result)
    }

    /// Handles the message, and tells the test whether that threw.
    @MainActor
    func finish(handling: @MainActor (Message) async throws -> Void) async {
        take()
        do {
            try await handling(message)
            finish()
        } catch {
            finish(.failure(error))
        }
    }

    deinit {
        // A message that no reader took was never received: its reader had stopped.
        finish(wasTaken ? .success(()) : .failure(MessageReceiverGone()))
    }
}

/// A receiver stopped before a message reached it, so it does not count as one.
struct MessageReceiverGone: Error {}

/// The messages of one type that a UI test sends, in the order they arrive.
///
/// Get one from ``UITestMessages/messages(of:)``.
public struct UITestMessageSequence<Message: UITestMessage>: AsyncSequence, Sendable {
    public typealias Element = Message

    let deliveries: AsyncStream<MessageDelivery<Message>>

    /// Returns an iterator, which receives messages for as long as it is read.
    public func makeAsyncIterator() -> Iterator {
        Iterator(deliveries: deliveries.makeAsyncIterator())
    }

    /// Reads the messages of a ``UITestMessageSequence``.
    public struct Iterator: AsyncIteratorProtocol {
        var deliveries: AsyncStream<MessageDelivery<Message>>.Iterator
        var current: MessageDelivery<Message>?

        /// Returns the next message. Asking for it tells the test that the one
        /// before has been handled.
        public mutating func next() async -> Message? {
            current?.finish()
            current = await deliveries.next()
            current?.take()
            return current?.message
        }
    }
}
