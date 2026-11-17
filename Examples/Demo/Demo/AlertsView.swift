import SwiftUI
import UITestingCore

/// A button that shows an alert and one that shows a confirmation dialog, and a line
/// of text that says which of their buttons was chosen.
struct AlertsView: View {
    @State private var isAlertShowing = false
    @State private var isDialogShowing = false
    @State private var outcome = "Nothing chosen"

    var body: some View {
        VStack(spacing: 24) {
            Text(outcome)
                .accessibilityIdentifier(AlertsID.outcome)

            Button("Delete the draft") { isAlertShowing = true }
                .accessibilityIdentifier(AlertsID.deleteButton)

            Button("Share the draft") { isDialogShowing = true }
                .accessibilityIdentifier(AlertsID.shareButton)
        }
        .padding()
        .alert("Delete the draft?", isPresented: $isAlertShowing) {
            Button("Delete", role: .destructive) { outcome = "Deleted" }
                .accessibilityIdentifier(AlertsID.confirmDeleteButton)
            Button("Cancel", role: .cancel) { outcome = "Kept" }
        } message: {
            Text("This cannot be undone.")
        }
        .confirmationDialog("Share the draft?", isPresented: $isDialogShowing, titleVisibility: .visible) {
            Button("Copy link") { outcome = "Copied" }
            Button("Discard", role: .destructive) { outcome = "Discarded" }
            Button("Cancel", role: .cancel) { outcome = "Not shared" }
        }
    }
}
