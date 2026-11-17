import SwiftUI
import UITestingCore

/// A list of messages with swipe actions on each row, and a line of text that says
/// which action was used last.
struct InboxView: View {
    struct Message: Identifiable {
        let id: Int
        let subject: String
    }

    @State private var messages = [
        Message(id: 1, subject: "Welcome"),
        Message(id: 2, subject: "Invoice"),
        Message(id: 3, subject: "Reminder"),
    ]
    @State private var lastAction = "Nothing yet"

    var body: some View {
        VStack {
            Text(lastAction)
                .accessibilityIdentifier(InboxID.lastAction)

            List(messages) { message in
                Text(message.subject)
                    .accessibilityIdentifier(InboxID.row(message.id))
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            messages.removeAll { $0.id == message.id }
                            lastAction = "Deleted \(message.subject)"
                        }
                        .accessibilityIdentifier(InboxID.deleteButton(message.id))

                        Button("Flag") { lastAction = "Flagged \(message.subject)" }
                    }
                    .swipeActions(edge: .leading) {
                        Button("Read") { lastAction = "Read \(message.subject)" }
                    }
            }
        }
    }
}
