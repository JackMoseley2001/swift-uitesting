import UITesting
import XCTest

@UITestSuite
final class MessageTests: XCTestCase {
    @UITest
    func loadingShowsTheMessageAfterADelay(app: XCUIApplication) throws {
        let message = app.staticTexts[AccessibilityID.message]
        #expect(!message.exists)

        app.buttons[AccessibilityID.loadMessageButton].tap()

        try #require(message.exists, within: .seconds(5))
        #expect(message.label == "Hello from the demo app")
    }

    @UITest
    func loadingShowsTheMessageInAnAsyncTest(app: XCUIApplication) async throws {
        let message = app.staticTexts[AccessibilityID.message]

        app.buttons[AccessibilityID.loadMessageButton].tap()

        try await #require(message.exists, within: .seconds(5))
        #expect(message.label == "Hello from the demo app")
    }
}
