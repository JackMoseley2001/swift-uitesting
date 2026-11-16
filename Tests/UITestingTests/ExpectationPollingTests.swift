import Testing

@testable import UITesting

@Suite
struct ExpectationPollingTests {
    /// A clock that only moves when the polling sleeps.
    private final class ManualClock {
        var now = ContinuousClock.now
        var sleeps: [Duration] = []

        var polling: ExpectationPolling {
            ExpectationPolling(
                interval: .milliseconds(100),
                now: { self.now },
                sleep: { duration in
                    self.sleeps.append(duration)
                    self.now += duration
                }
            )
        }
    }

    @Test
    func withoutATimeoutTheConditionIsEvaluatedOnce() {
        let clock = ManualClock()
        var evaluations = 0

        let result = clock.polling.wait(timeout: nil) {
            evaluations += 1
            return false
        }

        #Testing::expect(!result)
        #Testing::expect(evaluations == 1)
        #Testing::expect(clock.sleeps.isEmpty)
    }

    @Test
    func conditionThatIsAlreadyTrueDoesNotWait() {
        let clock = ManualClock()

        let result = clock.polling.wait(timeout: .seconds(5)) { true }

        #Testing::expect(result)
        #Testing::expect(clock.sleeps.isEmpty)
    }

    @Test
    func conditionIsEvaluatedAgainUntilItIsTrue() {
        let clock = ManualClock()
        var evaluations = 0

        let result = clock.polling.wait(timeout: .seconds(5)) {
            evaluations += 1
            return evaluations == 4
        }

        #Testing::expect(result)
        #Testing::expect(evaluations == 4)
        #Testing::expect(clock.sleeps == Array(repeating: .milliseconds(100), count: 3))
    }

    @Test
    func givesUpWhenTheTimeoutHasPassed() {
        let clock = ManualClock()
        var evaluations = 0

        let result = clock.polling.wait(timeout: .milliseconds(250)) {
            evaluations += 1
            return false
        }

        #Testing::expect(!result)
        #Testing::expect(evaluations == 4)
        #Testing::expect(clock.sleeps == [.milliseconds(100), .milliseconds(100), .milliseconds(50)])
    }

    @Test
    func errorFromTheConditionIsThrown() {
        let clock = ManualClock()

        #Testing::expect(throws: TestError(message: "condition")) {
            try clock.polling.wait(timeout: .seconds(1)) {
                throw TestError(message: "condition")
            }
        }
    }
}
