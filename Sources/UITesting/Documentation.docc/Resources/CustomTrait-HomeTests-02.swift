import UITesting
import XCTest

@UITestSuite(traits: .skipOnboarding, .feed("three-posts"))
final class HomeTests: XCTestCase {
    @UITest
    func opensOnTheFeed(app: XCUIApplication) {
        #expect(app[HomeID.feed].exists)
    }

    @UITest(traits: .feed("empty"))
    func saysWhenThereIsNothingToShow(app: XCUIApplication) {
        #expect(app[HomeID.emptyMessage].label == "Nothing here yet")
    }
}
