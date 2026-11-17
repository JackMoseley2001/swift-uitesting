import UITesting
import XCTest

@UITestSuite(traits: .launch(AuthState(isLoggedIn: true, name: "Ada")))
final class AccountTests: XCTestCase {
    @UITest
    func showsTheSignedInUser(app: XCUIApplication) {
        #expect(app[AccountID.authStatus].label == "Signed in")
        #expect(app[AccountID.userName].label == "Ada")
    }
}
