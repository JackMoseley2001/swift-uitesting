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

    /// The test reached its time limit while waiting for the condition, before the timeout
    /// had passed. The value is the time limit.
    case timeLimitReached(Duration)
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
            switch pause(timeout: timeout, start: start) {
            case .wait(let duration): sleep(duration)
            case .stop(let outcome): return outcome
            }
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
            switch pause(timeout: timeout, start: start) {
            case .wait(let duration):
                do {
                    try await suspend(duration)
                } catch {
                    // A time limit cancels the test when its time is up, at about the moment
                    // this wait would have noticed the deadline itself. Report it the same way.
                    if let timeLimit = TestTimeLimit.current, now() >= timeLimit.deadline {
                        return .timeLimitReached(timeLimit.limit)
                    }
                    return .cancelled(timeout)
                }
            case .stop(let outcome):
                return outcome
            }
        }
    }

    private enum Pause {
        case wait(Duration)
        case stop(WaitOutcome)
    }

    /// Decides what to do after the condition was false: wait before checking again, or stop
    /// because the timeout or the test's time limit has passed.
    private func pause(timeout: Duration, start: ContinuousClock.Instant) -> Pause {
        let current = now()
        let remaining = timeout - (current - start)
        guard remaining > .zero else {
            return .stop(.timedOut(timeout))
        }
        guard let timeLimit = TestTimeLimit.current else {
            return .wait(min(interval, remaining))
        }
        let untilDeadline = timeLimit.deadline - current
        guard untilDeadline > .zero else {
            return .stop(.timeLimitReached(timeLimit.limit))
        }
        return .wait(min(interval, remaining, untilDeadline))
    }
}

extension Duration {
    /// The duration in seconds.
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }

    /// The duration as it is written in a failure message, such as "5 seconds".
    var describedInSeconds: String {
        let seconds = timeInterval
        return "\(String(format: "%g", seconds)) \(seconds == 1 ? "second" : "seconds")"
    }
}
