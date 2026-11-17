import UITesting
import XCTest

@UITestSuite(traits: .skipOnboarding, .requiresStaging)
final class CheckoutTests: XCTestCase {
    @UITest
    func completesAPurchase(app: XCUIApplication) throws {
        try app[CheckoutID.payButton].tap()

        #expect(app[CheckoutID.receipt].exists, within: .seconds(10))
    }
}
