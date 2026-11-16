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
    /// func loadsTheFeedFromALocalServer(app: XCUIApplication) async throws {
    ///     // Your own code: something whose details are only known once the test is running.
    ///     let server = try await LocalServer.start()
    ///     app.launchEnvironment["API_URL"] = server.url.absoluteString
    ///     app.launch()
    ///
    ///     // ...
    /// }
    /// ```
    ///
    /// To launch with further traits, call ``UITestContext/relaunch(with:)``.
    ///
    /// The `willLaunch(_:)` and `setUp(_:)` steps of every trait still run before the
    /// test, which in a test with this trait means `setUp(_:)` runs before the app has
    /// launched. A trait that looks for something in the app during `setUp(_:)` does
    /// not work with this trait.
    ///
    /// If several tests need the same work done before the launch, write a trait with a
    /// `willLaunch(_:)` step instead.
    ///
    /// On a suite, this applies to every test in the suite.
    public static var manualLaunch: Self {
        ManualLaunchTrait()
    }
}
