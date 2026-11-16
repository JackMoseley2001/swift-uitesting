import UITesting
import XCTest

@UITestSuite(.loggedIn(as: "Ada"))
final class AuthenticationTests: XCTestCase {
    @MainActor
    func testShowsTheNamePassedByTheTest() async throws {
        try await UITestRunner.run(self) { context in
            let app = context.app

            XCTAssertEqual(app.staticTexts[AccessibilityID.authStatus].label, "Signed in")
            XCTAssertEqual(app.staticTexts[AccessibilityID.userName].label, "Ada")
        }
    }

    @MainActor
    func testATestCanOverrideItsSuite() async throws {
        try await UITestRunner.run(self, traits: [.loggedOut]) { context in
            let app = context.app

            XCTAssertEqual(app.staticTexts[AccessibilityID.authStatus].label, "Signed out")
            XCTAssertFalse(app.staticTexts[AccessibilityID.userName].exists)
            XCTAssertFalse(app.buttons[AccessibilityID.signOutButton].exists)
        }
    }

    @MainActor
    func testSigningOutUpdatesTheStatus() async throws {
        try await UITestRunner.run(self) { context in
            let app = context.app

            app.buttons[AccessibilityID.signOutButton].tap()

            XCTAssertEqual(app.staticTexts[AccessibilityID.authStatus].label, "Signed out")
            XCTAssertFalse(app.staticTexts[AccessibilityID.userName].exists)
        }
    }
}
