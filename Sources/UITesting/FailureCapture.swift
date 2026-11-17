import XCTest

/// Attaches what the app looked like to a test that has failed.
///
/// The capture is made once for a test, at its first failure, because that is the
/// moment the screen shows what went wrong.
@MainActor
final class FailureCapture {
    private let attach: @MainActor () -> Void
    private(set) var hasCaptured = false

    /// - Parameter attach: Adds the attachments to the test.
    init(attach: @escaping @MainActor () -> Void) {
        self.attach = attach
    }

    /// Creates a capture that attaches a screenshot and the app's element hierarchy to a test.
    convenience init(app: XCUIApplication, testCase: XCTestCase) {
        self.init {
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Screen at failure"
            screenshot.lifetime = .keepAlways
            testCase.add(screenshot)

            // Reading the hierarchy of an app that is not running would fail the test again.
            guard app.state == .runningForeground else { return }
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "Element hierarchy at failure"
            hierarchy.lifetime = .keepAlways
            testCase.add(hierarchy)
        }
    }

    /// Makes the capture, unless it has been made already.
    func captureOnce() {
        guard !hasCaptured else { return }
        hasCaptured = true
        attach()
    }

}

/// The capture for the running test.
enum RunningTest {
    /// The capture for the running test, if the test attaches anything on failure.
    @TaskLocal static var failureCapture: FailureCapture?

    /// The answers the running test gives to system alerts, if it gives any.
    @TaskLocal static var systemAlertRules: SystemAlertRules?

    /// Answers a system alert that is showing, if the running test's traits say how.
    ///
    /// Does nothing off the main thread, where the UI testing APIs cannot be used.
    static func answerSystemAlerts() {
        #if os(iOS)
            guard let rules = systemAlertRules, Thread.isMainThread else { return }
            MainActor.assumeIsolated {
                _ = SystemAlert.current.answer(with: rules)
            }
        #endif
    }

    /// Makes the running test's capture from code that is not isolated to the main actor.
    ///
    /// Does nothing off the main thread, where the UI testing APIs cannot be used.
    static func captureFailure() {
        guard let capture = failureCapture, Thread.isMainThread else { return }
        MainActor.assumeIsolated {
            capture.captureOnce()
        }
    }
}
