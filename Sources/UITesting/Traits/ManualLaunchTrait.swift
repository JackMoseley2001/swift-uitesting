/// A trait that leaves launching the app to the test.
///
/// Create one with ``UITestTrait/manualLaunch``.
public struct ManualLaunchTrait: UITestTrait {}

extension UITestTrait where Self == ManualLaunchTrait {
    /// Leaves launching the app to the test, so the test can do something first.
    ///
    /// The app is still configured with the test's traits. The test launches it by
    /// calling `launch()` on the app:
    ///
    /// ```swift
    /// @UITest(traits: .manualLaunch)
    /// func asksForAccessToPhotos(app: XCUIApplication) {
    ///     app.resetAuthorizationStatus(for: .photos)
    ///     app.launch()
    ///
    ///     app.buttons["choose-photo-button"].tap()
    ///     // ...
    /// }
    /// ```
    ///
    /// To launch with further traits, call ``UITestContext/relaunch(with:)``.
    ///
    /// The `setUp(_:)` step of every trait still runs before the test, which in a test
    /// with this trait is before the app has launched. A trait that looks for
    /// something in the app during `setUp(_:)` does not work with this trait.
    ///
    /// On a suite, this applies to every test in the suite.
    public static var manualLaunch: Self {
        ManualLaunchTrait()
    }
}
