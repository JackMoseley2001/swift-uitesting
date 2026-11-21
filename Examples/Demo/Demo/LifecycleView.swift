import SwiftUI
import UITestingCore

/// The links the app has been asked to open since it started.
@MainActor
final class OpenedLinks: ObservableObject {
    static let shared = OpenedLinks()

    @Published var latest: URL?
}

/// Shows how many times the app has gone to the background since it started, and the
/// last link it was asked to open, so that UI tests can leave the app and come back.
///
/// Both are kept in memory only, so they start again when the app is launched.
struct LifecycleView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var links = OpenedLinks.shared
    @State private var backgroundCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                row("Times in the background", "\(backgroundCount)", LifecycleID.backgroundCount)
                row("Opened link", links.latest?.absoluteString ?? "none", LifecycleID.openedLink)
            }
            .font(.footnote)
            .padding()
        }
        // The form of onChange that iOS 16 has. It is deprecated from iOS 17.
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                backgroundCount += 1
            }
        }
    }

    private func row(_ title: String, _ value: String, _ identifier: LifecycleID.StaticText) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .accessibilityIdentifier(identifier)
        }
    }
}
