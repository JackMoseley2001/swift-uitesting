import UITesting
import XCTest

@UITestSuite
final class ScrollingTests: XCTestCase {
    @UITest
    func aRowFurtherDownDoesNotExistUntilItIsScrolledTo(app: XCUIApplication) throws {
        #expect(!app[NumberID.row(40)].exists)

        try app[NumberID.row(40)].scrollIntoView().tap()

        #expect(app[NumberID.selection].label == "Selected 40")
    }

    @UITest
    func scrollsToTheLastRow(app: XCUIApplication) throws {
        try app[NumberID.row(60)].scrollIntoView().tap()

        #expect(app[NumberID.selection].label == "Selected 60")
    }

    @UITest
    func scrollsBackUp(app: XCUIApplication) throws {
        try app[NumberID.row(30)].scrollIntoView()
        #expect(!app[AccessibilityID.authStatus].isHittable)

        try app[AccessibilityID.authStatus].scrollIntoView(.up)

        #expect(app[AccessibilityID.authStatus].isHittable)
    }

    @UITest
    func findsAnElementInTheOtherDirection(app: XCUIApplication) throws {
        // Nothing is above the top of the screen, so the search turns round.
        try app[NumberID.row(20)].scrollIntoView(.up).tap()

        #expect(app[NumberID.selection].label == "Selected 20")
    }

    @UITest
    func doesNothingWhenTheElementIsInView(app: XCUIApplication) throws {
        let top = app[AccessibilityID.authStatus].frame

        try app[AccessibilityID.authStatus].scrollIntoView()

        #expect(app[AccessibilityID.authStatus].frame == top)
    }
}
