/// Whether the app is running, and where.
enum AppRunState: Equatable {
    /// The app is not running.
    case notRunning

    /// The app is running in the background, or is suspended there.
    case background

    /// The app is running in the foreground.
    case foreground

    /// XCTest does not know the state of the app.
    case unknown
}

/// Waits for the app to go to the background, and describes what went wrong if it does not.
enum AppStateWait {
    /// Sends an app that is running to the background, and waits until it is there or the
    /// timeout has passed.
    ///
    /// The wait is left to XCTest, because it only learns of a change in the app's state
    /// while it is waiting for one.
    ///
    /// - Parameters:
    ///   - state: Reads the state of the app.
    ///   - leave: Leaves the app, such as by pressing the Home button.
    ///   - reachesBackground: Waits for the app to be in the background for up to the
    ///     given time, and returns whether it got there.
    /// - Returns: `nil` if the app went to the background, and a description of the failure if not.
    static func failureToReachBackground(
        timeout: Duration,
        state: () -> AppRunState,
        leave: () -> Void,
        reachesBackground: (Duration) -> Bool
    ) -> String? {
        let summary = "Could not send the app to the background"
        guard state() != .notRunning else {
            return "\(summary): the app is not running"
        }

        leave()
        guard !reachesBackground(timeout) else { return nil }

        let time = ExpectationFailure.describe(timeout)
        switch state() {
        case .notRunning: return "\(summary): the app stopped running"
        case .foreground: return "\(summary): the app was still in the foreground after \(time)"
        case .unknown: return "\(summary): the state of the app was not known after \(time)"
        case .background: return nil
        }
    }
}

/// How a link is opened, which depends on whether the app is running.
enum LinkOpening: Equatable {
    /// The system opens the link, and the app that is running receives it.
    case throughTheSystem

    /// The app is launched with the link.
    case byLaunchingTheApp

    init(appState: AppRunState) {
        self = appState == .notRunning ? .byLaunchingTheApp : .throughTheSystem
    }
}
