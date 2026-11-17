import Foundation

/// What the app has asked to be done with each type of message.
@MainActor
package final class MessageReceivers {
    private var receivers: [String: [Int: @MainActor (Data) async throws -> Void]] = [:]
    private var nextToken = 0

    package init() {}

    /// Adds a receiver, and returns the token that removes it.
    package func add<Message: UITestMessage>(
        _ type: Message.Type,
        perform: @escaping @MainActor (Message) async throws -> Void
    ) -> Int {
        nextToken += 1
        receivers[Message.messageName, default: [:]][nextToken] = { body in
            try await perform(JSONDecoder().decode(Message.self, from: body))
        }
        return nextToken
    }

    package func remove(_ token: Int, named name: String) {
        receivers[name]?[token] = nil
    }

    /// Passes a message to its receivers, in the order they were added, and says how that went.
    package func handle(_ envelope: MessageEnvelope) async -> MessageReply {
        let matching = (receivers[envelope.name] ?? [:]).sorted { $0.key < $1.key }
        guard !matching.isEmpty else {
            return MessageReply(id: envelope.id, outcome: .noReceiver)
        }
        var received = false
        do {
            for (_, receive) in matching {
                do {
                    try await receive(envelope.body)
                    received = true
                } catch is MessageReceiverGone {
                }
            }
        } catch {
            return MessageReply(id: envelope.id, outcome: .failed("\(error)"))
        }
        return MessageReply(id: envelope.id, outcome: received ? .handled : .noReceiver)
    }
}
