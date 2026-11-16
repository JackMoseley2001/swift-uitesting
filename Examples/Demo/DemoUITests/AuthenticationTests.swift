import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class AuthenticationTests: XCTestCase {
    @UITest
    func showsTheNamePassedByTheTest(app: XCUIApplication) {
        XCTAssertEqual(app.staticTexts[AccessibilityID.authStatus].label, "Signed in")
        XCTAssertEqual(app.staticTexts[AccessibilityID.userName].label, "Ada")
    }

    @UITest(traits: .loggedOut)
    func aTestCanOverrideItsSuite(app: XCUIApplication) {
        XCTAssertEqual(app.staticTexts[AccessibilityID.authStatus].label, "Signed out")
        XCTAssertFalse(app.staticTexts[AccessibilityID.userName].exists)
        XCTAssertFalse(app.buttons[AccessibilityID.signOutButton].exists)
    }

    @UITest
    func signingOutUpdatesTheStatus(app: XCUIApplication) {
        app.buttons[AccessibilityID.signOutButton].tap()

        XCTAssertEqual(app.staticTexts[AccessibilityID.authStatus].label, "Signed out")
        XCTAssertFalse(app.staticTexts[AccessibilityID.userName].exists)
    }
}
