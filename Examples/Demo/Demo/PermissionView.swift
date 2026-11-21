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
                    status = await isMicrophoneAllowed() ? "Allowed" : "Denied"
                }
            }
            .accessibilityIdentifier(PermissionID.askButton)
        }
        .padding()
    }
}

/// Asks for the microphone, which shows the system's alert the first time.
private func isMicrophoneAllowed() async -> Bool {
    if #available(iOS 17.0, *) {
        return await AVAudioApplication.requestRecordPermission()
    }
    // Only iOS has an audio session, and only iOS is built for a version this old.
    #if os(iOS)
    return await withCheckedContinuation { continuation in
        AVAudioSession.sharedInstance().requestRecordPermission { isAllowed in
            continuation.resume(returning: isAllowed)
        }
    }
    #endif
}
