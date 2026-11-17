import UITesting
import XCTest

@UITestSuite(traits: .loggedOut)
final class SignInTests: XCTestCase {
    @UITest
    func signsIn(app: XCUIApplication) throws {
        try app[LoginID.emailField].enter("ada@example.com")
        try app[LoginID.passwordField].enter("analytical")
        try app[LoginID.signInButton].tap()

        #expect(app[HomeID.greeting].label == "Hello, Ada", within: .seconds(5))
    }
}
