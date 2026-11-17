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
    func deletesSeveralRowsOneAfterAnother(app: XCUIApplication) throws {
        for id in [3, 1] {
            try app[InboxID.row(id)].swipeAction("Delete")
            try app[InboxID.row(id)].waitToDisappear()
        }

        #expect(app[InboxID.row(2)].exists)
    }
}
