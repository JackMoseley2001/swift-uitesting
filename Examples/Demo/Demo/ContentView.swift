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
        // Lets a drag put the keyboard away, which is how UI tests dismiss it after
        // typing into the multi-line editor.
        .scrollDismissesKeyboard(.immediately)
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

            ProfileForm()

            Divider()

            FruitList()

            Divider()

            LaunchSettingsView()

            Divider()

            NumberList()
        }
        .padding()
    }
}
