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

    @UITest
    func explainsAWrongPassword(app: XCUIApplication) throws {
        try app[LoginID.emailField].enter("ada@example.com")
        try app[LoginID.passwordField].enter("wrong")
        try app[LoginID.signInButton].tap()

        try #require(app[LoginID.errorMessage].exists, within: .seconds(5))
        #expect(app[LoginID.errorMessage].label == "That password is not right")
        #expect(!app[HomeID.greeting].exists)
    }
}
