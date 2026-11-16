import UITesting
import XCTest

@UITestSuite
final class MessageTests: XCTestCase {
    @MainActor
    func testLoadingShowsTheMessageAfterADelay() async throws {
        try await UITestRunner.run(self) { context in
            let app = context.app
            let message = app.staticTexts[AccessibilityID.message]
            XCTAssertFalse(message.exists)

            app.buttons[AccessibilityID.loadMessageButton].tap()

            XCTAssertTrue(message.waitForExistence(timeout: 5))
            XCTAssertEqual(message.label, "Hello from the demo app")
        }
    }
}
