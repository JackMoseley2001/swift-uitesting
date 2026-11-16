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
    /// identifier's ``ElementID/accessibilityIdentifier``.
    ///
    /// - Parameter id: The identifier for the view.
    public func accessibilityIdentifier(_ id: some ElementID) -> some View {
        accessibilityIdentifier(id.accessibilityIdentifier)
    }
}
#endif
