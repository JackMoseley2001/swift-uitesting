import UITesting
import XCTest

extension UITestTrait where Self == DarkAppearance {
    /// Switches the device to its dark appearance for the test.
    static var darkAppearance: Self { DarkAppearance() }
}

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

    @UITest(traits: .darkAppearance)
    func showsTheDarkLogo(app: XCUIApplication) {
        #expect(app[HomeID.logo].label == "Logo, dark")
    }
}
