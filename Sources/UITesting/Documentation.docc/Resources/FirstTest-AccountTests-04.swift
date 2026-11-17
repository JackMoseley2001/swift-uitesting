import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class AccountTests: XCTestCase {
    @UITest
    func showsTheSignedInUser(app: XCUIApplication) {
        #expect(app[AccountID.authStatus].label == "Signed in")
        #expect(app[AccountID.userName].label == "Ada")
    }

    @UITest(traits: .loggedOut)
    func showsNoUserWhenSignedOut(app: XCUIApplication) {
        #expect(app[AccountID.authStatus].label == "Signed out")
        #expect(!app[AccountID.userName].exists)
    }

    @UITest
    func signingOutUpdatesTheStatus(app: XCUIApplication) throws {
        try app[AccountID.signOutButton].tap()
        try app[AccountID.signOutButton].waitToDisappear()

        #expect(app[AccountID.authStatus].label == "Signed out")
        #expect(!app[AccountID.userName].exists)
    }
}
