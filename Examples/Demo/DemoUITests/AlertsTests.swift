import UITesting
import XCTest

@UITestSuite(traits: .example(.alerts), .animationsDisabled)
final class AlertsTests: XCTestCase {
    @UITest
    func readsAnAlert(app: XCUIApplication) throws {
        #expect(!app.alert.isShowing)
        try app[AlertsID.deleteButton].tap()

        try app.alert.waitToAppear()

        #expect(app.alert.title == "Delete the draft?")
        #expect(app.alert.message == "This cannot be undone.")
        #expect(Set(app.alert.buttons) == ["Cancel", "Delete"])
    }

    @UITest
    func tapsAButtonOfAnAlertByItsLabel(app: XCUIApplication) throws {
        try app[AlertsID.deleteButton].tap()

        try app.alert.tap("Cancel")

        try app.alert.waitToDisappear()
        #expect(app[AlertsID.outcome].label == "Kept")
    }

    // watchOS does not report the identifier of a button of an alert.
    #if !os(watchOS)
    @UITest
    func tapsAButtonOfAnAlertByItsIdentifier(app: XCUIApplication) throws {
        try app[AlertsID.deleteButton].tap()

        try app.alert[AlertsID.confirmDeleteButton].tap()

        #expect(app[AlertsID.outcome].label == "Deleted", within: .seconds(2))
    }
    #endif

    @UITest
    func tapsAButtonOfADialog(app: XCUIApplication) throws {
        try app[AlertsID.shareButton].tap()
        #expect(app.dialog.title == "Share the draft?", within: .seconds(2))

        try app.dialog.tap("Discard")

        try app.dialog.waitToDisappear()
        #expect(app[AlertsID.outcome].label == "Discarded")
    }

    // A dialog closes when tapped outside only where it is shown as a popover, which is
    // not on macOS, visionOS or tvOS.
    #if !os(macOS) && !os(visionOS) && !os(tvOS)
    @UITest
    func dismissesADialog(app: XCUIApplication) throws {
        try app[AlertsID.shareButton].tap()

        try app.dialog.dismiss()

        #expect(!app.dialog.isShowing)
        #expect(app[AlertsID.outcome].label == "Not shared", within: .seconds(2))
    }
    #endif
}
