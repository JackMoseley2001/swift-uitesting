import UITesting
import XCTest

@UITestSuite
final class PromoBannerTests: XCTestCase {
    @UITest
    func bannerIsHiddenByDefault(app: XCUIApplication) {
        XCTAssertFalse(app.staticTexts[AccessibilityID.promoBanner].exists)
    }

    @UITest(traits: .promoBanner)
    func bannerIsShownWhenTheTestAsksForIt(app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts[AccessibilityID.promoBanner].exists)
    }
}
