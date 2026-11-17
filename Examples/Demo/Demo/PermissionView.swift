import AVFAudio
import SwiftUI

/// A button that asks for the microphone, which makes the system show a permission
/// alert, and a line of text that says how the alert was answered.
struct PermissionView: View {
    @State private var status = "Not asked"

    var body: some View {
        VStack(spacing: 24) {
            Text(status)
                .accessibilityIdentifier(PermissionID.status)

            Button("Ask for the microphone") {
                Task {
                    let isAllowed = await AVAudioApplication.requestRecordPermission()
                    status = isAllowed ? "Allowed" : "Denied"
                }
            }
            .accessibilityIdentifier(PermissionID.askButton)
        }
        .padding()
    }
}
