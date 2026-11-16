import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class RelaunchTests: XCTestCase {
    @UITest
    func relaunchingStartsTheAppAgainWithTheSameTraits(context: UITestContext) throws {
        let app = context.app
        app.buttons[AccessibilityID.signOutButton].tap()
        #expect(app.staticTexts[AccessibilityID.authStatus].label == "Signed out")

        try context.relaunch()

        #expect(app.staticTexts[AccessibilityID.authStatus].label == "Signed in")
        #expect(app.staticTexts[AccessibilityID.userName].label == "Ada")
    }

    @UITest
    func relaunchingCanChangeTheTraits(context: UITestContext) throws {
        let app = context.app
        #expect(app.staticTexts[AccessibilityID.authStatus].label == "Signed in")

        try context.relaunch(with: .loggedOut)

        #expect(app.staticTexts[AccessibilityID.authStatus].label == "Signed out")
        #expect(!app.staticTexts[AccessibilityID.promoBanner].exists)

        try context.relaunch(with: .promoBanner)

        // Each relaunch starts from the test's traits, so the app is signed in again.
        #expect(app.staticTexts[AccessibilityID.authStatus].label == "Signed in")
        #expect(app.staticTexts[AccessibilityID.promoBanner].exists)
    }

    @UITest(traits: .manualLaunch)
    func theTestLaunchesTheApp(app: XCUIApplication) {
        // The app is configured with the traits but is not running yet, so the test
        // can still change how it launches.
        app.launchArguments.append(LaunchArgument.showPromoBanner)
        app.launch()

        #expect(app.staticTexts[AccessibilityID.promoBanner].exists)
        #expect(app.staticTexts[AccessibilityID.userName].label == "Ada")
    }

    @UITest(traits: .manualLaunch)
    func theTestLaunchesTheAppWithMoreTraits(context: UITestContext) throws {
        try context.relaunch(with: .loggedOut)

        #expect(context.app.staticTexts[AccessibilityID.authStatus].label == "Signed out")
    }
}
