#if canImport(Darwin)
import XCTest

/// A test case whose tests are run by ``UITestRunner``.
///
/// ```swift
/// final class LoginTests: XCTestCase, UITestSuite {
///     static var suiteTraits: [any UITestTrait] {
///         [.launch(AuthState(isLoggedIn: false))]
///     }
/// }
/// ```
public protocol UITestSuite: XCTestCase {
    /// The traits that apply to every test in the suite.
    ///
    /// These are applied before the traits of an individual test, so a test can
    /// override them. The default is no traits.
    static var suiteTraits: [any UITestTrait] { get }
}

extension UITestSuite {
    public static var suiteTraits: [any UITestTrait] { [] }
}
#endif
