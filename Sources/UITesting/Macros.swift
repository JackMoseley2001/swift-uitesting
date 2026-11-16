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
/// In a test that is not `async`, the wait blocks between checks, in the same way as
/// `XCUIElement.waitForExistence(timeout:)`. In an `async` test, write `await` before
/// the macro. The wait then suspends the test between checks, so other work on the
/// main actor can run, and it ends early if the test's task is cancelled.
///
/// ```swift
/// @UITest
/// func loadsTheMessage(app: XCUIApplication) async {
///     app.buttons["load-message-button"].tap()
///     await #expect(app.staticTexts["message"].exists, within: .seconds(5))
/// }
/// ```
///
/// Without a timeout the macro never needs `await`.
///
/// ## Failure messages
///
/// A failure shows the source code of the condition and, if you pass one, your comment.
/// When the condition compares two values with `==`, it also shows how they differ.
/// Lines starting with `-` are what was expected, the value on the right of `==`, and
/// lines starting with `+` are what was found, the value on the left:
///
/// ```
/// Expectation failed: app.staticTexts["auth-status"].label == "Signed in"
/// - "Signed in"
/// + "Signed out"
/// ```
///
/// ## Using Swift Testing in the same file
///
/// Swift Testing has a macro with the same name, so `#expect` is ambiguous in a file
/// that imports both `Testing` and `UITesting`. In such a file, use
/// ``UITestingExpect(_:_:within:)``, which is this macro under a name of its own.
///
/// From Swift 6.3 you can also write the name of the module before either macro:
/// `#UITesting::expect(…)` or `#Testing::expect(…)`. For this macro that form also
/// needs swift-syntax 603 or later, if your package graph pins it.
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

/// Checks that a condition is true, under a name that does not clash with Swift Testing.
///
/// This is ``expect(_:_:within:)`` with a different name. Use it in a file that imports
/// both `Testing` and `UITesting`, where `#expect` is ambiguous. It works with every
/// version of Swift this package supports.
///
/// ```swift
/// #UITestingExpect(app.staticTexts["message"].exists, within: .seconds(5))
/// ```
///
/// - Parameters:
///   - condition: The condition to check. It cannot contain `await`.
///   - comment: A comment to include in the failure message.
///   - timeout: How long to wait for the condition to become true. By default the
///     condition is checked once.
@freestanding(expression)
public macro UITestingExpect(
    _ condition: Bool,
    _ comment: @autoclosure () -> String? = nil,
    within timeout: Duration? = nil
) = #externalMacro(module: "UITestingMacros", type: "ExpectMacro")

/// Checks that a condition is true, and ends the test if it is not.
///
/// Use this instead of ``expect(_:_:within:)`` when the rest of the test makes no sense
/// unless the condition holds. A failure is recorded against the test and then thrown,
/// so the call is written with `try`.
///
/// ```swift
/// @UITest
/// func showsTheLoadedMessage(app: XCUIApplication) throws {
///     app.buttons["load-message-button"].tap()
///
///     try #require(app.staticTexts["message"].exists, within: .seconds(5))
///     #expect(app.staticTexts["message"].label == "Hello")
/// }
/// ```
///
/// It takes the same arguments as `#expect`, waits in the same way, and shows how the
/// two sides of a comparison with `==` differ. In an `async` test, a call with a timeout
/// is written `try await #require(…, within: …)`.
///
/// In a file that also imports Swift Testing, which has a macro with the same name, use
/// `#UITestingRequire` instead.
///
/// - Parameters:
///   - condition: The condition to check. It cannot contain `await`.
///   - comment: A comment to include in the failure message.
///   - timeout: How long to wait for the condition to become true. By default the
///     condition is checked once.
/// - Throws: ``RequirementFailedError`` if the condition is not true.
@freestanding(expression)
public macro require(
    _ condition: Bool,
    _ comment: @autoclosure () -> String? = nil,
    within timeout: Duration? = nil
) = #externalMacro(module: "UITestingMacros", type: "RequireMacro")

/// Returns the value of an optional, and ends the test if it is `nil`.
///
/// ```swift
/// let title = try #require(app.staticTexts["title"].value as? String)
/// #expect(title.hasPrefix("Welcome"))
/// ```
///
/// A failure is recorded against the test and then thrown, so the call is written with
/// `try`. Pass a timeout to wait for a value to become available; in an `async` test
/// that call is written with `try await`.
///
/// In a file that also imports Swift Testing, which has a macro with the same name, use
/// `#UITestingRequire` instead.
///
/// - Parameters:
///   - optionalValue: The value to unwrap. It cannot contain `await`.
///   - comment: A comment to include in the failure message.
///   - timeout: How long to wait for a value. By default the value is read once.
/// - Returns: The unwrapped value.
/// - Throws: ``RequirementFailedError`` if the value is `nil`.
@freestanding(expression)
@discardableResult
public macro require<Value>(
    _ optionalValue: Value?,
    _ comment: @autoclosure () -> String? = nil,
    within timeout: Duration? = nil
) -> Value = #externalMacro(module: "UITestingMacros", type: "RequireValueMacro")

/// Checks that a condition is true and ends the test if it is not, under a name that
/// does not clash with Swift Testing.
///
/// This is `#require` with a different name. Use it in a file that imports both `Testing`
/// and `UITesting`, where `#require` is ambiguous. It works with every version of Swift
/// this package supports.
///
/// - Parameters:
///   - condition: The condition to check. It cannot contain `await`.
///   - comment: A comment to include in the failure message.
///   - timeout: How long to wait for the condition to become true. By default the
///     condition is checked once.
/// - Throws: ``RequirementFailedError`` if the condition is not true.
@freestanding(expression)
public macro UITestingRequire(
    _ condition: Bool,
    _ comment: @autoclosure () -> String? = nil,
    within timeout: Duration? = nil
) = #externalMacro(module: "UITestingMacros", type: "RequireMacro")

/// Returns the value of an optional and ends the test if it is `nil`, under a name that
/// does not clash with Swift Testing.
///
/// This is `#require` with a different name. Use it in a file that imports both `Testing`
/// and `UITesting`, where `#require` is ambiguous.
///
/// - Parameters:
///   - optionalValue: The value to unwrap. It cannot contain `await`.
///   - comment: A comment to include in the failure message.
///   - timeout: How long to wait for a value. By default the value is read once.
/// - Returns: The unwrapped value.
/// - Throws: ``RequirementFailedError`` if the value is `nil`.
@freestanding(expression)
@discardableResult
public macro UITestingRequire<Value>(
    _ optionalValue: Value?,
    _ comment: @autoclosure () -> String? = nil,
    within timeout: Duration? = nil
) -> Value = #externalMacro(module: "UITestingMacros", type: "RequireValueMacro")
