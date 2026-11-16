import UITestingCore

/// The signed-in state a UI test asks the app to start in.
struct AuthState: LaunchPayload {
    var isLoggedIn: Bool
    var name: String?
}
