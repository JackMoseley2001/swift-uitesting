import UITesting
import XCTest

@UITestSuite(traits: .example(.lifecycle), .animationsDisabled)
final class LifecycleTests: XCTestCase {
    @UITest
    func appKeepsRunningInTheBackground(context: UITestContext) throws {
        let app = context.app
        #expect(app[LifecycleID.backgroundCount].label == "0")

        try context.background()
        context.foreground()

        #expect(app[LifecycleID.backgroundCount].label == "1")
    }

    @UITest
    func terminatedAppStartsAgainWithTheTestsTraits(context: UITestContext) throws {
        let app = context.app
        try context.background()
        context.foreground()
        #expect(app[LifecycleID.backgroundCount].label == "1")

        context.terminate()
        #expect(app.state == .notRunning)
        context.foreground()

        // The count is back at zero because the app started again, and the screen is
        // showing because it started with the suite's example.
        #expect(app[LifecycleID.backgroundCount].label == "0")
    }

    @UITest
    func runningAppReceivesALink(context: UITestContext) throws {
        let app = context.app
        try context.background()

        context.open(DemoLink.order(42))

        #expect(app[LifecycleID.openedLink].label == "uitestingdemo://orders/42")
        #expect(app[LifecycleID.backgroundCount].label == "1")
    }

    @UITest
    func linkLaunchesAnAppThatIsNotRunning(context: UITestContext) {
        let app = context.app
        context.terminate()

        context.open(DemoLink.order(7))

        #expect(app[LifecycleID.openedLink].label == "uitestingdemo://orders/7")
    }

    @UITest
    func relaunchingWithALinkStartsTheAppAgain(context: UITestContext) throws {
        let app = context.app
        try context.background()
        context.foreground()
        #expect(app[LifecycleID.backgroundCount].label == "1")

        try context.relaunch(opening: DemoLink.order(3))

        #expect(app[LifecycleID.openedLink].label == "uitestingdemo://orders/3")
        #expect(app[LifecycleID.backgroundCount].label == "0")
    }
}
