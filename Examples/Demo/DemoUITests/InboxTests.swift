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

    @UITest
    func pullsTheListToRefreshIt(app: XCUIApplication) throws {
        #expect(!app[InboxID.row(4)].exists)

        try app[InboxID.list].pullToRefresh()

        #expect(app[InboxID.lastAction].label == "Refreshed", within: .seconds(5))
        #expect(app[InboxID.row(4)].label == "Update 4")
    }

    @UITest
    func refreshesTwice(app: XCUIApplication) throws {
        try app[InboxID.list].pullToRefresh()
        try app[InboxID.row(4)].waitToAppear()

        try app[InboxID.list].pullToRefresh()
        try app[InboxID.row(5)].waitToAppear()
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
