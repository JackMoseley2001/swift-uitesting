import UITesting
import XCTest

@UITestSuite(traits: .launch(AuthState(isLoggedIn: true, name: "Ada")))
final class AccountTests: XCTestCase {
}
