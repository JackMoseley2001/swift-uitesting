import UITestingCore

/// Identifiers for the account example.
///
/// The app tags a view with a member and a test finds it with the same member. The
/// type of each member says what kind of element it is, so a test does not have to.
/// Each identifier is prefixed with the name of this type, so it cannot clash with an
/// identifier from another group.
enum AccountID: ElementIDs {
    static var authStatus: StaticText { element() }
    static var userName: StaticText { element() }
    static var signOutButton: Button { element() }
    static var promoBanner: StaticText { element() }
}
