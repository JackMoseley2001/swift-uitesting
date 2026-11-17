import UITesting
import XCTest

@UITestSuite(traits: .example(.account), .loggedIn(as: "Ada"), .animationsDisabled)
final class RelaunchTests: XCTestCase {
    @UITest
    func relaunchingStartsTheAppAgainWithTheSameTraits(context: UITestContext) throws {
        let app = context.app
        try app[AccountID.signOutButton].tap()
        #expect(app[AccountID.authStatus].label == "Signed out")

        try context.relaunch()

        #expect(app[AccountID.authStatus].label == "Signed in")
        #expect(app[AccountID.userName].label == "Ada")
    }

    @UITest
    func relaunchingCanChangeTheTraits(context: UITestContext) throws {
        let app = context.app
        #expect(app[AccountID.authStatus].label == "Signed in")

        try context.relaunch(with: .loggedOut)

        #expect(app[AccountID.authStatus].label == "Signed out")
        #expect(!app[AccountID.promoBanner].exists)

        try context.relaunch(with: .promoBanner)

        // Each relaunch starts from the test's traits, so the app is signed in again.
        #expect(app[AccountID.authStatus].label == "Signed in")
        #expect(app[AccountID.promoBanner].exists)
    }

    @UITest(traits: .manualLaunch)
    func theTestLaunchesTheApp(app: XCUIApplication) {
        // The app is configured with the traits but is not running yet, so the test
        // can still change how it launches.
        app.launchArguments.append(LaunchArgument.showPromoBanner)
        app.launch()

        #expect(app[AccountID.promoBanner].exists)
        #expect(app[AccountID.userName].label == "Ada")
    }

    @UITest(traits: .manualLaunch)
    func theTestLaunchesTheAppWithMoreTraits(context: UITestContext) throws {
        try context.relaunch(with: .loggedOut)

        #expect(context.app[AccountID.authStatus].label == "Signed out")
    }
}
