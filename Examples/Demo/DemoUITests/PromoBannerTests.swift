import UITesting
import XCTest

@UITestSuite
final class PromoBannerTests: XCTestCase {
    @MainActor
    func testBannerIsHiddenByDefault() async throws {
        try await UITestRunner.run(self) { context in
            XCTAssertFalse(context.app.staticTexts[AccessibilityID.promoBanner].exists)
        }
    }

    @MainActor
    func testBannerIsShownWhenTheTestAsksForIt() async throws {
        try await UITestRunner.run(self, traits: [.promoBanner]) { context in
            XCTAssertTrue(context.app.staticTexts[AccessibilityID.promoBanner].exists)
        }
    }
}
