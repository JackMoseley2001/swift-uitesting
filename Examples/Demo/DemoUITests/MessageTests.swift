import UITesting
import XCTest

@UITestSuite
final class MessageTests: XCTestCase {
    @UITest
    func loadingShowsTheMessageAfterADelay(app: XCUIApplication) {
        let message = app.staticTexts[AccessibilityID.message]
        #expect(!message.exists)

        app.buttons[AccessibilityID.loadMessageButton].tap()

        #expect(message.exists, within: .seconds(5))
        #expect(message.label == "Hello from the demo app")
    }
}
