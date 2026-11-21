import UITesting
import XCTest

@UITestSuite(traits: .example(.inbox), .animationsDisabled)
final class InboxTests: XCTestCase {
    @UITest
    func usesATrailingSwipeActionByItsLabel(app: XCUIApplication) throws {
        try app[InboxID.row(2)].swipeAction("Flag")

        #expect(app[InboxID.lastAction].label == "Flagged Invoice", within: .seconds(2))
        #expect(app[InboxID.row(2)].exists)
    }

    @UITest
    func usesALeadingSwipeAction(app: XCUIApplication) throws {
        try app[InboxID.row(3)].swipeAction("Read", edge: .leading)

        #expect(app[InboxID.lastAction].label == "Read Reminder", within: .seconds(2))
    }

    @UITest
    func usesASwipeActionByItsIdentifier(app: XCUIApplication) throws {
        try app[InboxID.row(1)].swipeAction(InboxID.deleteButton(1))

        try app[InboxID.row(1)].waitToDisappear()
        #expect(app[InboxID.lastAction].label == "Deleted Welcome")
        #expect(app[InboxID.row(2)].exists)
    }

    // A Mac app has no pull to refresh.
    #if !os(macOS)
    @UITest
    func pullsTheListToRefreshIt(app: XCUIApplication) throws {
        #expect(!app[InboxID.row(4)].exists)

        try app[InboxID.list].pullToRefresh()

        #expect(app[InboxID.lastAction].label == "Refreshed", within: .seconds(5))
        #expect(app[InboxID.row(4)].label == "Update 4")
    }
    #endif

    // A Mac app has no pull to refresh.
    #if !os(macOS)
    @UITest
    func refreshesTwice(app: XCUIApplication) throws {
        try app[InboxID.list].pullToRefresh()
        try app[InboxID.row(4)].waitToAppear()

        try app[InboxID.list].pullToRefresh()
        try app[InboxID.row(5)].waitToAppear()
    }
    #endif

    @UITest
    func countsTheRowsInsideTheList(app: XCUIApplication) {
        #expect(app[InboxID.list][all: InboxID.row].count == 3)
        #expect(app[InboxID.list][all: InboxID.row].map(\.label) == ["Welcome", "Invoice", "Reminder"])
    }

    // A Mac app has no pull to refresh.
    #if !os(macOS)
    @UITest
    func waitsForTheNumberOfRowsToChange(app: XCUIApplication) throws {
        try app[InboxID.list].pullToRefresh()

        // The new message arrives a second after the pull.
        #expect(app[all: InboxID.row].count == 4, within: .seconds(5))
        #expect(app[all: InboxID.row].map(\.label) == ["Welcome", "Invoice", "Reminder", "Update 4"])
    }
    #endif

    @UITest
    func anElementKeepsToItsRowWhenTheListChanges(app: XCUIApplication) throws {
        let first = app[all: InboxID.row][0]
        #expect(first.label == "Welcome")

        try first.swipeAction("Delete")

        // Another row is first now, and this is still the one that was deleted.
        try first.waitToDisappear()
        #expect(app[all: InboxID.row].count == 2)
        #expect(app[all: InboxID.row][0].label == "Invoice")
    }

    @UITest
    func deletesSeveralRowsOneAfterAnother(app: XCUIApplication) throws {
        for id in [3, 1] {
            try app[InboxID.row(id)].swipeAction("Delete")
            try app[InboxID.row(id)].waitToDisappear()
        }

        #expect(app[InboxID.row(2)].exists)
    }
}
