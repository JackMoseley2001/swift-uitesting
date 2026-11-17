import UITesting
import XCTest

@UITestSuite(traits: .example(.message), .animationsDisabled)
final class MessageTests: XCTestCase {
    @UITest
    func loadingShowsTheMessageAfterADelay(app: XCUIApplication) throws {
        let message = app[MessageID.message]
        #expect(!message.exists)

        try app[MessageID.loadButton].tap()

        try message.waitToAppear()
        #expect(message.label == "Hello from the demo app")
    }

    @UITest
    func loadingShowsTheMessageInAnAsyncTest(app: XCUIApplication) async throws {
        let message = app[MessageID.message]

        try app[MessageID.loadButton].tap()

        try await #require(message.exists, within: .seconds(5))
        #expect(message.label == "Hello from the demo app")
    }
}
