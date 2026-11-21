import UITesting
import XCTest

@UITestSuite(traits: .example(.numberList), .animationsDisabled)
final class ScrollingTests: XCTestCase {
    @UITest
    func aRowFurtherDownDoesNotExistUntilItIsScrolledTo(app: XCUIApplication) throws {
        // A list on macOS creates all of its rows, so the row exists there, out of view.
        #if !os(macOS)
        #expect(!app[NumberID.row(40)].exists)
        #endif

        try app[NumberID.row(40)].scrollIntoView().tap()

        #expect(app[NumberID.selection].label == "Selected 40")
    }

    // A list on macOS creates all of its rows.
    #if !os(macOS)
    @UITest
    func onlyTheRowsThatAreLoadedAreCounted(app: XCUIApplication) throws {
        try app[NumberID.row(1)].waitToAppear()

        // The list has 60 numbers, and creates rows for the ones near the screen.
        let loaded = app[all: NumberID.row].count

        #expect(loaded > 0)
        #expect(loaded < 60)
    }
    #endif

    @UITest
    func scrollsToTheLastRow(app: XCUIApplication) throws {
        try app[NumberID.row(60)].scrollIntoView().tap()

        #expect(app[NumberID.selection].label == "Selected 60")
    }

    @UITest
    func scrollsBackUp(app: XCUIApplication) throws {
        try app[NumberID.row(40)].scrollIntoView()
        // A list on macOS creates all of its rows, so the row exists there, out of view.
        #if !os(macOS)
        #expect(!app[NumberID.row(1)].exists)
        #endif

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
