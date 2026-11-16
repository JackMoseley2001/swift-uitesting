import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class RelaunchTests: XCTestCase {
    @UITest
    func relaunchingStartsTheAppAgainWithTheSameTraits(context: UITestContext) throws {
        let app = context.app
        try app[AccessibilityID.signOutButton].tap()
        #expect(app[AccessibilityID.authStatus].label == "Signed out")

        try context.relaunch()

        #expect(app[AccessibilityID.authStatus].label == "Signed in")
        #expect(app[AccessibilityID.userName].label == "Ada")
    }

    @UITest
    func relaunchingCanChangeTheTraits(context: UITestContext) throws {
        let app = context.app
        #expect(app[AccessibilityID.authStatus].label == "Signed in")

        try context.relaunch(with: .loggedOut)

        #expect(app[AccessibilityID.authStatus].label == "Signed out")
        #expect(!app[AccessibilityID.promoBanner].exists)

        try context.relaunch(with: .promoBanner)

        // Each relaunch starts from the test's traits, so the app is signed in again.
        #expect(app[AccessibilityID.authStatus].label == "Signed in")
        #expect(app[AccessibilityID.promoBanner].exists)
    }

    @UITest(traits: .manualLaunch)
    func theTestLaunchesTheApp(app: XCUIApplication) {
        // The app is configured with the traits but is not running yet, so the test
        // can still change how it launches.
        app.launchArguments.append(LaunchArgument.showPromoBanner)
        app.launch()

        #expect(app[AccessibilityID.promoBanner].exists)
        #expect(app[AccessibilityID.userName].label == "Ada")
    }

    @UITest(traits: .manualLaunch)
    func theTestLaunchesTheAppWithMoreTraits(context: UITestContext) throws {
        try context.relaunch(with: .loggedOut)

        #expect(context.app[AccessibilityID.authStatus].label == "Signed out")
    }
}
