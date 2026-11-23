import UITesting
import XCTest

@UITestSuite(traits: .example(.lifecycle), .animationsDisabled)
final class LifecycleTests: XCTestCase {
    // The library sends the app to the background on iOS only.
    #if os(iOS)
    @UITest
    func appKeepsRunningInTheBackground(context: UITestContext) throws {
        let app = context.app
        #expect(app[LifecycleID.backgroundCount].label == "0")

        try context.background()
        context.foreground()

        #expect(app[LifecycleID.backgroundCount].label == "1")
    }
    #endif

    // The library sends the app to the background on iOS only.
    #if os(iOS)
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
    #endif

    // The library sends the app to the background on iOS only.
    #if os(iOS)
    @UITest
    func runningAppReceivesALink(context: UITestContext) throws {
        let app = context.app
        try context.background()

        context.open(DemoLink.order(42))

        // The app is given the link a moment after the call returns, and after it has
        // drawn its first screen when the link launched it.
        #expect(app[LifecycleID.openedLink].label == "uitestingdemo://orders/42", within: .seconds(5))
        #expect(app[LifecycleID.backgroundCount].label == "1")
    }
    #endif

    // On watchOS an app that a link launches is not given the arguments and environment
    // of the test, so it does not open on this example.
    #if !os(watchOS)
    @UITest
    func linkLaunchesAnAppThatIsNotRunning(context: UITestContext) {
        let app = context.app
        context.terminate()

        context.open(DemoLink.order(7))

        #expect(app[LifecycleID.openedLink].label == "uitestingdemo://orders/7", within: .seconds(5))
    }
    #endif

    // The library sends the app to the background on iOS only.
    #if os(iOS)
    @UITest
    func relaunchingWithALinkStartsTheAppAgain(context: UITestContext) throws {
        let app = context.app
        try context.background()
        context.foreground()
        #expect(app[LifecycleID.backgroundCount].label == "1")

        try context.relaunch(opening: DemoLink.order(3))

        #expect(app[LifecycleID.openedLink].label == "uitestingdemo://orders/3", within: .seconds(5))
        #expect(app[LifecycleID.backgroundCount].label == "0")
    }
    #endif
}
