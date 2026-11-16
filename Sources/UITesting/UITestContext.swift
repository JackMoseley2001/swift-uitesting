#if canImport(Darwin)
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

    /// The configuration the app was launched with, after every trait was applied.
    public let launch: LaunchConfiguration
}
#endif
