import XCTest

/// A trait that makes the app forget whether it was given access to protected resources.
///
/// Create one with ``UITestTrait/resetAuthorization(for:)``.
public struct ResetAuthorizationTrait: UITestTrait {
    /// The resources whose authorization is reset.
    public let resources: [XCUIProtectedResource]

    @MainActor
    public func willLaunch(_ context: UITestContext) async throws {
        for resource in resources {
            context.app.resetAuthorizationStatus(for: resource)
        }
    }
}

extension UITestTrait where Self == ResetAuthorizationTrait {
    /// Resets the app's authorization for protected resources before it launches.
    ///
    /// The app starts as if it had never asked for access, so the system shows its
    /// permission alert again the next time the app asks.
    ///
    /// ```swift
    /// @UITest(traits: .resetAuthorization(for: .photos, .camera))
    /// func asksForAccessToPhotos(app: XCUIApplication) {
    ///     app.buttons["choose-photo-button"].tap()
    ///     // ...
    /// }
    /// ```
    ///
    /// The reset happens once, before the first launch. It is not repeated by
    /// ``UITestContext/relaunch(with:within:)``, so a test can check that the app keeps the
    /// access it was given across a restart.
    ///
    /// - Parameter resources: The resources to reset, such as `.photos` or `.location`.
    public static func resetAuthorization(for resources: XCUIProtectedResource...) -> Self {
        ResetAuthorizationTrait(resources: resources)
    }
}
