import UITesting
import XCTest

// The library answers the alerts of the system on iOS only.
#if os(iOS)
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
        // The title has "Microphone" before iOS 27.
        #expect(alert.title.lowercased().contains("microphone"))
        #expect(alert.buttons.count == 2)

        try alert.tapButton(at: 0)

        try alert.waitToDisappear()
        #expect(app[PermissionID.status].label == "Denied", within: .seconds(3))
    }

    // Before iOS 27 a trait for a resource resets it and answers nothing, so that the
    // test answers the alert itself.
    @UITest(traits: .systemAlerts(.deny, for: .microphone), .enabled(if: !alertsSayWhatTheyAskFor))
    func aTraitForAResourceLeavesTheAlertToTheTestBeforeIOS27(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        try SystemAlert.current.allow()

        #expect(app[PermissionID.status].label == "Allowed", within: .seconds(3))
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

/// Whether the system marks an alert with the resource it asks for, which it does from iOS 27.
private var alertsSayWhatTheyAskFor: Bool {
    if #available(iOS 27, *) { true } else { false }
}

/// Tests that leave the answer to a trait for one resource. Such a trait answers alerts
/// from iOS 27 only, because before that an alert does not say what it asks for.
@UITestSuite(
    traits: .example(.permission),
    .systemAlerts(.allow, for: .microphone),
    .animationsDisabled,
    .enabled(if: alertsSayWhatTheyAskFor)
)
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

    @UITest(traits: .systemAlerts(.deny, for: .camera))
    func aTraitForAnotherResourceDoesNotAnswerThisAlert(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        #expect(app[PermissionID.status].label == "Allowed", within: .seconds(5))
    }
}

/// Tests that leave the answer to a trait for every alert, which works on any version.
@UITestSuite(
    traits: .example(.permission),
    .resetAuthorization(for: .microphone),
    .systemAlerts(.allow),
    .animationsDisabled
)
final class SystemAlertEveryAlertTraitTests: XCTestCase {
    @UITest
    func theTraitAnswersTheAlert(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        #expect(app[PermissionID.status].label == "Allowed", within: .seconds(5))
        #expect(!SystemAlert.current.isShowing)
    }

    @UITest(traits: .systemAlerts(.deny))
    func aTestCanOverrideItsSuite(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        #expect(app[PermissionID.status].label == "Denied", within: .seconds(5))
    }

    @UITest(traits: .systemAlerts(.button("Don’t Allow")))
    func aTraitCanAnswerByLabel(app: XCUIApplication) throws {
        try app[PermissionID.askButton].tap()

        #expect(app[PermissionID.status].label == "Denied", within: .seconds(5))
    }
}
#endif
