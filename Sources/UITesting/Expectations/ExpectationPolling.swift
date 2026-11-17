import Foundation

/// How a check of a condition ended.
enum WaitOutcome: Equatable {
    /// The condition was true.
    case met

    /// The condition was checked once, without waiting, and was false.
    case notMet

    /// The condition was still false when the timeout had passed.
    case timedOut(Duration)

    /// The task was cancelled while waiting for the condition, before the timeout had passed.
    case cancelled(Duration)
}

/// Evaluates a condition, optionally repeating it until it holds or a timeout passes.
struct ExpectationPolling {
    /// How long to wait between evaluations of the condition.
    var interval: Duration = .milliseconds(100)

    /// Returns the current time.
    var now: () -> ContinuousClock.Instant = { ContinuousClock.now }

    /// Blocks the calling thread for the given duration.
    var sleep: (Duration) -> Void = { Thread.sleep(forTimeInterval: $0.timeInterval) }

    /// Suspends the current task for the given duration, and throws if the task is cancelled.
    var suspend: (Duration) async throws -> Void = { try await Task.sleep(for: $0) }

    /// Runs after each evaluation of the condition that was false, before the wait
    /// goes on. This is where system alerts are answered for a test that asked for that.
    var betweenEvaluations: () -> Void = { RunningTest.answerSystemAlerts() }

    /// Evaluates the condition once, or, with a timeout, repeatedly until it is true
    /// or the timeout has passed.
    ///
    /// The condition is always evaluated at least once. This blocks the calling thread
    /// between evaluations, in the same way as `XCUIElement.waitForExistence(timeout:)`.
    func wait(timeout: Duration?, until condition: () throws -> Bool) rethrows -> WaitOutcome {
        guard let timeout else {
            return try condition() ? .met : .notMet
        }

        let start = now()
        while true {
            if try condition() {
                return .met
            }
            let remaining = timeout - (now() - start)
            guard remaining > .zero else {
                return .timedOut(timeout)
            }
            betweenEvaluations()
            sleep(min(interval, remaining))
        }
    }

    /// Evaluates the condition repeatedly until it is true or the timeout has passed,
    /// suspending the task between evaluations.
    ///
    /// The condition is always evaluated at least once, in the isolation of the caller.
    /// Other work can run there between evaluations, and the wait ends early if the task
    /// is cancelled.
    func wait(
        timeout: Duration,
        isolation: isolated (any Actor)? = #isolation,
        until condition: () throws -> Bool
    ) async rethrows -> WaitOutcome {
        let start = now()
        while true {
            if try condition() {
                return .met
            }
            let remaining = timeout - (now() - start)
            guard remaining > .zero else {
                return .timedOut(timeout)
            }
            betweenEvaluations()
            do {
                try await suspend(min(interval, remaining))
            } catch {
                return .cancelled(timeout)
            }
        }
    }
}

extension Duration {
    /// The duration in seconds.
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}
