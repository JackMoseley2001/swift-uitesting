import UITesting
import XCTest

@UITestSuite(traits: .example(.account))
final class PromoBannerTests: XCTestCase {
    @UITest
    func bannerIsHiddenByDefault(app: XCUIApplication) {
        #expect(!app[AccountID.promoBanner].exists)
    }

    @UITest(traits: .promoBanner)
    func bannerIsShownWhenTheTestAsksForIt(app: XCUIApplication) {
        #expect(app[AccountID.promoBanner].exists)
    }
}
