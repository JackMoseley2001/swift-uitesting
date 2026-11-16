/// Declares a UI test suite and the traits that apply to every test in it.
///
/// Attach this macro to a class that inherits from `XCTestCase`. It conforms the class to
/// the ``UITestSuite`` protocol and uses the macro's arguments as the suite's traits.
///
/// ```swift
/// @UITestSuite(traits: .launch(AuthState(isLoggedIn: false)), .launchArgument("--skip-onboarding"))
/// final class LoginTests: XCTestCase {
///     @MainActor
///     func testShowsSignInButton() async throws {
///         try await UITestRunner.run(self) { context in
///             XCTAssertTrue(context.app.buttons["Sign in"].exists)
///         }
///     }
/// }
/// ```
///
/// The suite's traits are applied before the traits of an individual test, so a test can
/// override them. Written as `@UITestSuite` with no arguments, the suite has no traits.
///
/// - Parameter traits: The traits that apply to every test in the suite.
@attached(extension, conformances: UITestSuite, names: named(suiteTraits))
public macro UITestSuite(traits: any UITestTrait...) =
    #externalMacro(module: "UITestingMacros", type: "UITestSuiteMacro")
