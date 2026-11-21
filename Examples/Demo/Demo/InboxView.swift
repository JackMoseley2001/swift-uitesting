import SwiftUI
import UITestingCore

/// A list of messages with swipe actions on each row, which can be pulled down to
/// fetch one more, and a line of text that says which action was used last.
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
                    // tvOS has no swipe actions.
                    #if !os(tvOS)
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
                    #endif
            }
            .refreshable {
                // Long enough for a UI test to have to wait for the new message.
                try? await Task.sleep(for: .seconds(1))
                let id = (messages.map(\.id).max() ?? 0) + 1
                messages.append(Message(id: id, subject: "Update \(id)"))
                lastAction = "Refreshed"
            }
            .accessibilityIdentifier(InboxID.list)
        }
    }
}
