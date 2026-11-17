import UITesting
import XCTest

@UITestSuite(traits: .example(.numberList), .animationsDisabled)
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
        try app[NumberID.row(40)].scrollIntoView()
        #expect(!app[NumberID.row(1)].exists)

        try app[NumberID.row(1)].scrollIntoView(.up)

        #expect(app[NumberID.row(1)].isHittable)
    }

    @UITest
    func findsAnElementInTheOtherDirection(app: XCUIApplication) throws {
        // Nothing is above the top of the screen, so the search turns round.
        try app[NumberID.row(20)].scrollIntoView(.up).tap()

        #expect(app[NumberID.selection].label == "Selected 20")
    }

    @UITest
    func doesNothingWhenTheElementIsInView(app: XCUIApplication) throws {
        let top = app[NumberID.row(1)].frame

        try app[NumberID.row(1)].scrollIntoView()

        #expect(app[NumberID.row(1)].frame == top)
    }
}
