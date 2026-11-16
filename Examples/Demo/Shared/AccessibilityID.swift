import UITestingCore

/// Identifiers for the elements that UI tests look up.
///
/// The app tags a view with a case and a test finds it with the same case. Each
/// identifier is prefixed with the name of this type, so it cannot clash with an
/// identifier from another type.
enum AccessibilityID: ElementID {
    case authStatus
    case userName
    case signOutButton
    case promoBanner
    case loadMessageButton
    case message

    case preferredLanguage
    case region
    case betaFeatures
    case orientation
}
