import UITesting
import XCTest

@UITestSuite
final class MessageTests: XCTestCase {
    @UITest
    func loadingShowsTheMessageAfterADelay(app: XCUIApplication) throws {
        let message = app[AccessibilityID.message]
        #expect(!message.exists)

        try app[AccessibilityID.loadMessageButton].tap()

        try message.waitToAppear()
        #expect(message.label == "Hello from the demo app")
    }

    @UITest
    func loadingShowsTheMessageInAnAsyncTest(app: XCUIApplication) async throws {
        let message = app[AccessibilityID.message]

        try app[AccessibilityID.loadMessageButton].tap()

        try await #require(message.exists, within: .seconds(5))
        #expect(message.label == "Hello from the demo app")
    }
}
