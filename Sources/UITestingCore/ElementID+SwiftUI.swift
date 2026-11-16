#if canImport(SwiftUI)
import SwiftUI

extension View {
    /// Gives the view a typed accessibility identifier that a UI test can find it by.
    ///
    /// ```swift
    /// Button("Sign in") { signIn() }
    ///     .accessibilityIdentifier(LoginID.signInButton)
    /// ```
    ///
    /// This is SwiftUI's `accessibilityIdentifier(_:)` with the string taken from the
    /// identifier's ``ElementID/accessibilityIdentifier``. It does not check that the
    /// view is the kind of element the identifier is for. A UI test looks for that
    /// kind, so it does not find the element if the two differ.
    ///
    /// - Parameter id: The identifier for the view.
    public func accessibilityIdentifier<Kind: ElementKind>(_ id: ElementID<Kind>) -> some View {
        accessibilityIdentifier(id.accessibilityIdentifier)
    }
}
#endif
