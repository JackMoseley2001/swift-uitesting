import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class AuthenticationTests: XCTestCase {
    @UITest
    func showsTheNamePassedByTheTest(app: XCUIApplication) {
        #expect(app.staticTexts[AccessibilityID.authStatus].label == "Signed in")
        #expect(app.staticTexts[AccessibilityID.userName].label == "Ada")
    }

    @UITest(traits: .loggedOut)
    func aTestCanOverrideItsSuite(app: XCUIApplication) {
        #expect(app.staticTexts[AccessibilityID.authStatus].label == "Signed out")
        #expect(!app.staticTexts[AccessibilityID.userName].exists)
        #expect(!app.buttons[AccessibilityID.signOutButton].exists)
    }

    @UITest
    func signingOutUpdatesTheStatus(app: XCUIApplication) {
        app.buttons[AccessibilityID.signOutButton].tap()

        #expect(app.staticTexts[AccessibilityID.authStatus].label == "Signed out")
        #expect(!app.staticTexts[AccessibilityID.userName].exists)
    }
}
