import UITesting
import XCTest

@UITestSuite(traits: .example(.account), .loggedIn(as: "Ada"))
final class AuthenticationTests: XCTestCase {
    @UITest
    func showsTheNamePassedByTheTest(app: XCUIApplication) {
        #expect(app[AccountID.authStatus].label == "Signed in")
        #expect(app[AccountID.userName].label == "Ada")
    }

    @UITest(traits: .loggedOut)
    func aTestCanOverrideItsSuite(app: XCUIApplication) {
        #expect(app[AccountID.authStatus].label == "Signed out")
        #expect(!app[AccountID.userName].exists)
        #expect(!app[AccountID.signOutButton].exists)
    }

    @UITest
    func signingOutUpdatesTheStatus(app: XCUIApplication) throws {
        try app[AccountID.signOutButton].tap()
        try app[AccountID.signOutButton].waitToDisappear()

        #expect(app[AccountID.authStatus].label == "Signed out")
        #expect(!app[AccountID.userName].exists)
    }
}
