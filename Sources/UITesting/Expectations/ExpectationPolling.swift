import Foundation

/// Evaluates a condition, optionally repeating it until it holds or a timeout passes.
struct ExpectationPolling {
    /// How long to wait between evaluations of the condition.
    var interval: Duration = .milliseconds(100)

    /// Returns the current time.
    var now: () -> ContinuousClock.Instant = { ContinuousClock.now }

    /// Blocks the calling thread for the given duration.
    var sleep: (Duration) -> Void = { Thread.sleep(forTimeInterval: $0.timeInterval) }

    /// Evaluates the condition once, or, with a timeout, repeatedly until it is true
    /// or the timeout has passed.
    ///
    /// The condition is always evaluated at least once, and blocks the calling thread
    /// between evaluations, in the same way as `XCUIElement.waitForExistence(timeout:)`.
    ///
    /// - Returns: Whether the condition was true.
    func wait(timeout: Duration?, until condition: () throws -> Bool) rethrows -> Bool {
        guard let timeout else {
            return try condition()
        }

        let start = now()
        while true {
            if try condition() {
                return true
            }
            let remaining = timeout - (now() - start)
            guard remaining > .zero else {
                return false
            }
            sleep(min(interval, remaining))
        }
    }
}

extension Duration {
    /// The duration in seconds.
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}
