import UITesting
import XCTest

@UITestSuite
final class PromoBannerTests: XCTestCase {
    @UITest
    func bannerIsHiddenByDefault(app: XCUIApplication) {
        #expect(!app.staticTexts[AccessibilityID.promoBanner].exists)
    }

    @UITest(traits: .promoBanner)
    func bannerIsShownWhenTheTestAsksForIt(app: XCUIApplication) {
        #expect(app.staticTexts[AccessibilityID.promoBanner].exists)
    }
}
