import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class AuthenticationTests: XCTestCase {
    @UITest
    func showsTheNamePassedByTheTest(app: XCUIApplication) {
        #expect(app[AccessibilityID.authStatus].label == "Signed in")
        #expect(app[AccessibilityID.userName].label == "Ada")
    }

    @UITest(traits: .loggedOut)
    func aTestCanOverrideItsSuite(app: XCUIApplication) {
        #expect(app[AccessibilityID.authStatus].label == "Signed out")
        #expect(!app[AccessibilityID.userName].exists)
        #expect(!app[AccessibilityID.signOutButton].exists)
    }

    @UITest
    func signingOutUpdatesTheStatus(app: XCUIApplication) throws {
        try app[AccessibilityID.signOutButton].tap()
        try app[AccessibilityID.signOutButton].waitToDisappear()

        #expect(app[AccessibilityID.authStatus].label == "Signed out")
        #expect(!app[AccessibilityID.userName].exists)
    }
}
