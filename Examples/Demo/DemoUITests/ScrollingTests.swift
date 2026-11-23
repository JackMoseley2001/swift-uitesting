import UITesting
import XCTest

@UITestSuite(traits: .example(.numberList), .animationsDisabled)
final class ScrollingTests: XCTestCase {
    // A swipe moves a list by about half the height of the screen, which on a watch
    // is less than two rows, so the rows far down the list take more than the usual 20.
    private static let swipes = 60

    @UITest
    func aRowFurtherDownDoesNotExistUntilItIsScrolledTo(app: XCUIApplication) throws {
        // A list on macOS or tvOS creates all of its rows, so the row exists there, out of view.
        #if !os(macOS) && !os(tvOS)
        #expect(!app[NumberID.row(40)].exists)
        #endif

        try app[NumberID.row(40)].scrollIntoView(maximumSwipes: Self.swipes).tap()

        #expect(app[NumberID.selection].label == "Selected 40")
    }

    // A list on macOS or tvOS creates all of its rows.
    #if !os(macOS) && !os(tvOS)
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
        try app[NumberID.row(60)].scrollIntoView(maximumSwipes: Self.swipes).tap()

        #expect(app[NumberID.selection].label == "Selected 60")
    }

    @UITest
    func scrollsBackUp(app: XCUIApplication) throws {
        try app[NumberID.row(40)].scrollIntoView(maximumSwipes: Self.swipes)
        // A list on macOS or tvOS creates all of its rows, so the row exists there, out of view.
        #if !os(macOS) && !os(tvOS)
        #expect(!app[NumberID.row(1)].exists)
        #endif

        try app[NumberID.row(1)].scrollIntoView(.up, maximumSwipes: Self.swipes)

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
