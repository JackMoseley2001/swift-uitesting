import Foundation

/// A message on its way from a UI test to the app.
package struct MessageEnvelope: Codable, Sendable, Equatable {
    /// A number that the app's reply repeats, so the test can tell which message it answers.
    package var id: Int

    /// The ``UITestMessage/messageName`` of the message.
    package var name: String

    /// The message, encoded as JSON.
    package var body: Data

    package init(id: Int, name: String, body: Data) {
        self.id = id
        self.name = name
        self.body = body
    }
}

/// What the app did with a message.
package struct MessageReply: Codable, Sendable, Equatable {
    package enum Outcome: Codable, Sendable, Equatable {
        /// Every receiver of the message ran and returned.
        case handled

        /// Nothing in the app is receiving this type of message.
        case noReceiver

        /// The message could not be decoded, or a receiver threw.
        case failed(String)
    }

    /// The ``MessageEnvelope/id`` of the message this answers.
    package var id: Int

    package var outcome: Outcome

    package init(id: Int, outcome: Outcome) {
        self.id = id
        self.outcome = outcome
    }
}

/// Splits a stream of bytes into the lines it carries, one JSON value to a line.
package struct MessageLines {
    private var buffer = Data()

    package init() {}

    /// Adds bytes as they arrive, and returns the lines that are now complete.
    package mutating func append(_ data: Data) -> [Data] {
        buffer.append(data)
        var lines: [Data] = []
        while let newline = buffer.firstIndex(of: Self.newline) {
            lines.append(buffer[buffer.startIndex..<newline])
            buffer = Data(buffer[buffer.index(after: newline)...])
        }
        return lines.filter { !$0.isEmpty }
    }

    /// Returns a value as one line.
    package static func line(_ value: some Encodable) throws -> Data {
        var data = try JSONEncoder().encode(value)
        data.append(newline)
        return data
    }

    private static let newline = UInt8(ascii: "\n")
}
