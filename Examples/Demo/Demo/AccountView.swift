import SwiftUI
import UITestingCore

/// Shows whether a user is signed in, which UI tests set with a launch payload.
struct AccountView: View {
    @State private var auth: AuthState

    init(traits: LaunchTraits) {
        _auth = State(initialValue: traits[AuthState.self] ?? AuthState(isLoggedIn: false))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PromoBanner()

                Text(auth.isLoggedIn ? "Signed in" : "Signed out")
                    .font(.title)
                    .accessibilityIdentifier(AccountID.authStatus)

                if auth.isLoggedIn {
                    if let name = auth.name {
                        Text(name)
                            .accessibilityIdentifier(AccountID.userName)
                    }

                    Button("Sign out") {
                        auth = AuthState(isLoggedIn: false)
                    }
                    .accessibilityIdentifier(AccountID.signOutButton)
                }
            }
            .padding()
        }
    }
}
