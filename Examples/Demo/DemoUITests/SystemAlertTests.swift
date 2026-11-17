import UITesting
import XCTest

@UITestSuite(traits: .example(.permission), .resetAuthorization(for: .microphone), .animationsDisabled)
final class SystemAlertTests: XCTestCase {
    @UITest
    func allowingGivesTheAppAccess(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        try SystemAlert.current.allow()

        #expect(app[PermissionID.status].label == "Allowed", within: .seconds(3))
        #expect(!SystemAlert.current.isShowing)
    }

    @UITest
    func denyingRefusesTheApp(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        try SystemAlert.current.deny()

        #expect(app[PermissionID.status].label == "Denied", within: .seconds(3))
    }

    @UITest
    func aButtonCanBeChosenByItsLabel(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        try SystemAlert.current.tap("Allow")

        #expect(app[PermissionID.status].label == "Allowed", within: .seconds(3))
    }

    @UITest
    func aButtonCanBeChosenByItsPosition(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()
        let alert = SystemAlert.current
        try alert.waitToAppear()
        #expect(alert.title.contains("microphone"))
        #expect(alert.buttons.count == 2)

        try alert.tapButton(at: 0)

        try alert.waitToDisappear()
        #expect(app[PermissionID.status].label == "Denied", within: .seconds(3))
    }

    @UITest
    func theAnswerIsKeptUntilItIsReset(context: UITestContext) throws {
        try context.app[PermissionID.askButton].tap()
        try SystemAlert.current.allow()
        #expect(context.app[PermissionID.status].label == "Allowed", within: .seconds(3))

        try context.relaunch()
        try context.app[PermissionID.askButton].tap()

        #expect(context.app[PermissionID.status].label == "Allowed", within: .seconds(3))
        #expect(!SystemAlert.current.isShowing)
    }
}

/// Tests that leave the answer to a trait.
@UITestSuite(traits: .example(.permission), .systemAlerts(.allow, for: .microphone), .animationsDisabled)
final class SystemAlertTraitTests: XCTestCase {
    @UITest
    func theTraitAnswersWhileAnExpectationWaits(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        #expect(app[PermissionID.status].label == "Allowed", within: .seconds(5))
        #expect(!SystemAlert.current.isShowing)
    }

    @UITest(traits: .systemAlerts(.deny, for: .microphone))
    func aTestCanOverrideItsSuite(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        #expect(app[PermissionID.status].label == "Denied", within: .seconds(5))
    }

    @UITest
    func theTraitAnswersAnAlertThatBlocksAnAction(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()
        try SystemAlert.current.waitToAppear()

        // XCTest's own tap, which the alert is in the way of.
        app.buttons[PermissionID.askButton.accessibilityIdentifier].tap()

        #expect(!SystemAlert.current.isShowing)
        #expect(app[PermissionID.status].label == "Allowed", within: .seconds(5))
    }

    @UITest(traits: .systemAlerts(.button("Don’t Allow")))
    func aTraitCanAnswerByLabel(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        #expect(app[PermissionID.status].label == "Denied", within: .seconds(5))
    }

    @UITest(traits: .systemAlerts(.deny, for: .camera))
    func aTraitForAnotherResourceDoesNotAnswerThisAlert(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        #expect(app[PermissionID.status].label == "Allowed", within: .seconds(5))
    }
}
