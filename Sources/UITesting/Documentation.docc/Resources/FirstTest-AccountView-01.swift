import SwiftUI
import UITestingCore

struct AccountView: View {
    @State private var auth = AuthState(isLoggedIn: false)

    var body: some View {
        VStack(spacing: 24) {
            Text(auth.isLoggedIn ? "Signed in" : "Signed out")
                .font(.title)

            if auth.isLoggedIn {
                if let name = auth.name {
                    Text(name)
                }

                Button("Sign out") {
                    auth = AuthState(isLoggedIn: false)
                }
            }
        }
        .padding()
    }
}
