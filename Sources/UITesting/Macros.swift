/// Declares a UI test suite and the traits that apply to every test in it.
///
/// Attach this macro to a class that inherits from `XCTestCase`, and mark each test in
/// it with ``UITest(traits:)``.
///
/// ```swift
/// @UITestSuite(traits: .launch(AuthState(isLoggedIn: false)), .launchArgument("--skip-onboarding"))
/// final class LoginTests: XCTestCase {
///     @UITest
///     func showsSignInButton(app: XCUIApplication) {
///         XCTAssertTrue(app.buttons["Sign in"].exists)
///     }
/// }
/// ```
///
/// The macro conforms the class to the ``UITestSuite`` protocol, uses its arguments as the
/// suite's traits, and isolates each `@UITest` function to the main actor.
///
/// The suite's traits are applied before the traits of an individual test, so a test can
/// override them. Written as `@UITestSuite` with no arguments, the suite has no traits.
///
/// - Parameter traits: The traits that apply to every test in the suite.
@attached(extension, conformances: UITestSuite, names: named(suiteTraits))
@attached(memberAttribute)
public macro UITestSuite(traits: any UITestTrait...) =
    #externalMacro(module: "UITestingMacros", type: "UITestSuiteMacro")

/// Declares a UI test.
///
/// Attach this macro to a method of a class marked with ``UITestSuite(traits:)``. When the
/// test runs, the app is launched with the suite's traits and the test's own traits, and
/// then the method is called.
///
/// ```swift
/// @UITestSuite(traits: .launch(AuthState(isLoggedIn: false)))
/// final class LoginTests: XCTestCase {
///     @UITest
///     func showsSignInButton(app: XCUIApplication) {
///         XCTAssertTrue(app.buttons["Sign in"].exists)
///     }
///
///     @UITest(traits: .launch(AuthState(isLoggedIn: true)))
///     func skipsSignInWhenAuthenticated(app: XCUIApplication) {
///         XCTAssertTrue(app.staticTexts["Home"].exists)
///     }
/// }
/// ```
///
/// ## Parameters of a test
///
/// A test can take the launched app as an `XCUIApplication`, a ``UITestContext``, both, or
/// neither. The parameters can have any names and labels. The method can be `async`, can
/// throw, and must not return a value.
///
/// ```swift
/// @UITest
/// func dismissesSystemAlerts(context: UITestContext) async throws {
///     context.testCase.addUIInterruptionMonitor(withDescription: "System alert") { alert in
///         alert.buttons["Allow"].tap()
///         return true
///     }
///     context.app.buttons["Enable notifications"].tap()
/// }
/// ```
///
/// ## How the test is run
///
/// The macro adds a method named `test_` followed by the name of the function, which is what
/// XCTest discovers and runs. That name is the one shown in Xcode and in test reports. Do
/// not start the name of a test that takes no parameters with `test`, because XCTest would
/// then also run the function itself, without launching the app.
///
/// - Parameter traits: The traits for this test, applied after the suite's traits.
@attached(peer, names: prefixed(test_))
public macro UITest(traits: any UITestTrait...) =
    #externalMacro(module: "UITestingMacros", type: "UITestMacro")

/// Checks that a condition is true, and records a failure of the test if it is not.
///
/// The test continues after a failed expectation, so one run can report several.
///
/// ```swift
/// @UITest
/// func showsTheSignedInUser(app: XCUIApplication) {
///     #expect(app.staticTexts["auth-status"].label == "Signed in")
///     #expect(!app.buttons["sign-in-button"].exists)
/// }
/// ```
///
/// ## Waiting for a condition
///
/// Pass a timeout to wait for something that does not happen immediately. The condition
/// is checked repeatedly until it is true or the timeout has passed.
///
/// ```swift
/// app.buttons["load-message-button"].tap()
/// #expect(app.staticTexts["message"].exists, within: .seconds(5))
/// ```
///
/// ## Failure messages
///
/// A failure shows the source code of the condition and, if you pass one, your comment.
/// When the condition compares two values with `==`, it also shows how they differ:
///
/// ```
/// Expectation failed: app.staticTexts["auth-status"].label == "Signed in"
/// - "Signed out"
/// + "Signed in"
/// ```
///
/// ## Using Swift Testing in the same file
///
/// Swift Testing has a macro with the same name. In a file that imports both `Testing`
/// and `UITesting`, write the name of the module before the macro: `#UITesting::expect(…)`
/// or `#Testing::expect(…)`. This requires Swift 6.3 or later, and swift-syntax 603 or
/// later if your package graph pins it.
///
/// - Parameters:
///   - condition: The condition to check. It cannot contain `await`.
///   - comment: A comment to include in the failure message.
///   - timeout: How long to wait for the condition to become true. By default the
///     condition is checked once.
@freestanding(expression)
public macro expect(
    _ condition: Bool,
    _ comment: @autoclosure () -> String? = nil,
    within timeout: Duration? = nil
) = #externalMacro(module: "UITestingMacros", type: "ExpectMacro")
