import SwiftUI
import UITestingCore

struct ContentView: View {
    @State private var auth: AuthState
    @State private var message: String?

    init(traits: LaunchTraits) {
        _auth = State(initialValue: traits[AuthState.self] ?? AuthState(isLoggedIn: false))
    }

    var body: some View {
        ScrollView {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 24) {
            PromoBanner()

            Text(auth.isLoggedIn ? "Signed in" : "Signed out")
                .font(.title)
                .accessibilityIdentifier(AccessibilityID.authStatus)

            if auth.isLoggedIn {
                if let name = auth.name {
                    Text(name)
                        .accessibilityIdentifier(AccessibilityID.userName)
                }

                Button("Sign out") {
                    auth = AuthState(isLoggedIn: false)
                }
                .accessibilityIdentifier(AccessibilityID.signOutButton)
            }

            Divider()

            Button("Load message") {
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    message = "Hello from the demo app"
                }
            }
            .accessibilityIdentifier(AccessibilityID.loadMessageButton)

            if let message {
                Text(message)
                    .accessibilityIdentifier(AccessibilityID.message)
            }

            Divider()

            LaunchSettingsView()
        }
        .padding()
    }
}
