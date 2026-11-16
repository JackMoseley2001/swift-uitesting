/// A typed accessibility identifier for one kind of element.
///
/// You normally get one from a member of an ``ElementIDs`` group, where it is written
/// with a short name such as `Button` or `StaticText`:
///
/// ```swift
/// enum LoginID: ElementIDs {
///     static var signInButton: Button { element() }
/// }
/// ```
///
/// The kind is part of the type, so a UI test that looks an element up by its
/// identifier does not have to say what kind of element it is.
public struct ElementID<Kind: ElementKind>: Hashable, Sendable {
    /// The string to use as the element's accessibility identifier.
    ///
    /// In SwiftUI, pass the identifier itself to `accessibilityIdentifier(_:)`.
    /// Elsewhere, use this string:
    ///
    /// ```swift
    /// signInButton.accessibilityIdentifier = LoginID.signInButton.accessibilityIdentifier
    /// ```
    public let accessibilityIdentifier: String

    /// Creates an identifier from the exact string to use.
    ///
    /// Use this for an identifier the app already has. Otherwise, call
    /// ``ElementIDs/element(_:name:)`` from a member of a group, which builds a string
    /// that cannot clash with another group's.
    ///
    /// - Parameter accessibilityIdentifier: The element's accessibility identifier.
    public init(_ accessibilityIdentifier: String) {
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}
