import UITesting
import XCTest

@UITestSuite(traits: .skipOnboarding)
final class HomeTests: XCTestCase {
    @UITest
    func opensOnTheFeed(app: XCUIApplication) {
        #expect(app[HomeID.feed].exists)
    }
}
