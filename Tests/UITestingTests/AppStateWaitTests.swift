import Testing

@testable import UITesting

@Suite
struct AppStateWaitTests {
    /// Runs the wait for an app that starts in one state and is in another once it has been waited for.
    private func failure(
        from start: AppRunState,
        to end: AppRunState,
        left: (() -> Void)? = nil
    ) -> String? {
        var state = start
        return AppStateWait.failureToReachBackground(
            timeout: .seconds(5),
            state: { state },
            leave: { left?() },
            reachesBackground: { _ in
                state = end
                return end == .background
            }
        )
    }

    @Test
    func appThatReachesTheBackgroundPasses() {
        #Testing::expect(failure(from: .foreground, to: .background) == nil)
    }

    @Test
    func appIsLeftBeforeItIsWaitedFor() {
        var events: [String] = []

        _ = AppStateWait.failureToReachBackground(
            timeout: .seconds(5),
            state: { .foreground },
            leave: { events.append("leave") },
            reachesBackground: { timeout in
                events.append("wait \(timeout)")
                return true
            }
        )

        #Testing::expect(events == ["leave", "wait 5.0 seconds"])
    }

    @Test
    func appThatStaysInTheForegroundFails() {
        #Testing::expect(
            failure(from: .foreground, to: .foreground)
                == "Could not send the app to the background: the app was still in the foreground after 5 seconds"
        )
    }

    @Test
    func appThatIsNotRunningFailsWithoutBeingLeft() {
        var wasLeft = false

        let failure = failure(from: .notRunning, to: .background) { wasLeft = true }

        #Testing::expect(failure == "Could not send the app to the background: the app is not running")
        #Testing::expect(!wasLeft)
    }

    @Test
    func appThatStopsRunningFails() {
        #Testing::expect(
            failure(from: .foreground, to: .notRunning)
                == "Could not send the app to the background: the app stopped running"
        )
    }

    @Test
    func appWhoseStateIsNotKnownFails() {
        #Testing::expect(
            failure(from: .foreground, to: .unknown)
                == "Could not send the app to the background: the state of the app was not known after 5 seconds"
        )
    }

    @Test
    func linkGoesThroughTheSystemWhileTheAppIsRunning() {
        #Testing::expect(LinkOpening(appState: .foreground) == .throughTheSystem)
        #Testing::expect(LinkOpening(appState: .background) == .throughTheSystem)
        #Testing::expect(LinkOpening(appState: .unknown) == .throughTheSystem)
    }

    @Test
    func linkLaunchesAnAppThatIsNotRunning() {
        #Testing::expect(LinkOpening(appState: .notRunning) == .byLaunchingTheApp)
    }
}
