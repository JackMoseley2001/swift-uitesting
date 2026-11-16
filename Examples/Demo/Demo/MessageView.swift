import SwiftUI
import UITestingCore

/// Shows a message a moment after a button is tapped, so that UI tests have to wait for it.
struct MessageView: View {
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Button("Load message") {
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        message = "Hello from the demo app"
                    }
                }
                .accessibilityIdentifier(MessageID.loadButton)

                if let message {
                    Text(message)
                        .accessibilityIdentifier(MessageID.message)
                }
            }
            .padding()
        }
    }
}
