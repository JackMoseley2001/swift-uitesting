import UITestingCore

/// Identifiers for the account screen.
enum AccountID: ElementIDs {
    static var authStatus: StaticText { element() }
    static var userName: StaticText { element() }
    static var signOutButton: Button { element() }
}
