import UITestingCore

/// Identifiers for the sign-in screen and the screen it leads to.
enum LoginID: ElementIDs {
    static var emailField: TextField { element() }
    static var passwordField: SecureTextField { element() }
    static var signInButton: Button { element() }
    static var errorMessage: StaticText { element() }
}

enum HomeID: ElementIDs {
    static var greeting: StaticText { element() }
}
