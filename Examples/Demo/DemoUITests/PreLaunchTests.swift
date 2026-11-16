import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class PreLaunchTests: XCTestCase {
    @UITest(traits: .resetAuthorization(for: .photos))
    func theAppLaunchesAfterAPermissionIsReset(app: XCUIApplication) {
        #expect(app.staticTexts[AccessibilityID.userName].label == "Ada")
    }

    @UITest(traits: .endedBeforeLaunch)
    func aTraitCanActBeforeTheAppLaunches(app: XCUIApplication) {
        #expect(app.state == .runningForeground)
        #expect(app.staticTexts[AccessibilityID.userName].label == "Ada")
    }
}

/// Ends any instance of the app left running by an earlier test, just before this test launches it.
private struct EndedBeforeLaunch: UITestTrait {
    func willLaunch(_ context: UITestContext) async throws {
        context.app.terminate()
        #expect(context.app.state == .notRunning)
    }
}

extension UITestTrait where Self == EndedBeforeLaunch {
    fileprivate static var endedBeforeLaunch: Self { EndedBeforeLaunch() }
}
