import SwiftUI
import UITestingCore

struct AccountView: View {
    @State private var auth: AuthState

    init(traits: LaunchTraits = .current) {
        _auth = State(initialValue: traits[AuthState.self] ?? AuthState(isLoggedIn: false))
    }

    var body: some View {
        VStack(spacing: 24) {
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
        .onUITestMessage(ExpireSession.self) { _ in
            auth = AuthState(isLoggedIn: false)
        }
    }
}
