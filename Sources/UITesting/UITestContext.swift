import XCTest

/// The app and the test that a trait or test body is working with.
@MainActor
public struct UITestContext {
    /// The app under test.
    public let app: XCUIApplication

    /// The test case that is running.
    ///
    /// Use this for XCTest features that belong to the test case, such as
    /// `addUIInterruptionMonitor(withDescription:handler:)`.
    public let testCase: XCTestCase

    /// The configuration that the test's traits produced, which the app is launched with.
    ///
    /// ``relaunch(with:)`` does not change this value.
    public let launch: LaunchConfiguration

    /// Launches the app again, ending it first if it is running.
    ///
    /// Use this to check what the app does across a restart, such as whether it kept
    /// something the test did:
    ///
    /// ```swift
    /// @UITest
    /// func keepsTheDraftAcrossARestart(context: UITestContext) throws {
    ///     let app = context.app
    ///     app.textFields["draft-field"].tap()
    ///     app.textFields["draft-field"].typeText("Hello")
    ///
    ///     try context.relaunch()
    ///
    ///     #expect(app.textFields["draft-field"].value as? String == "Hello")
    /// }
    /// ```
    ///
    /// Pass traits to launch the app with a different configuration. They are applied
    /// after the test's own traits, so they can override them:
    ///
    /// ```swift
    /// try context.relaunch(with: .loggedOut)
    /// ```
    ///
    /// Each call starts from the test's traits. Traits passed to an earlier call are
    /// not carried over to a later one.
    ///
    /// Only the `prepare(_:)` step of the traits passed here is used, because that is
    /// the step that configures a launch. Their `willLaunch(_:)`, `setUp(_:)` and
    /// `tearDown(_:)` steps are not run, and the steps of the test's own traits are
    /// not run again.
    ///
    /// In a test with the ``UITestTrait/manualLaunch`` trait, this can also be the
    /// call that launches the app for the first time.
    ///
    /// - Parameter traits: Traits to apply on top of the test's traits for this launch.
    /// - Throws: An error thrown by a trait while it configures the launch.
    public func relaunch(with traits: any UITestTrait...) throws {
        app.configure(with: try launch.applying(traits))
        app.launch()
    }
}

extension XCUIApplication {
    /// Sets the arguments and environment that the app is launched with next.
    func configure(with launch: LaunchConfiguration) {
        launchArguments = launch.arguments
        launchEnvironment = launch.environment
    }
}
