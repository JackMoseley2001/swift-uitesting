import Testing

@testable import UITesting

@Suite
struct ExpectationPollingTests {
    /// A clock that only moves when the polling sleeps.
    private final class ManualClock {
        var now = ContinuousClock.now
        var sleeps: [Duration] = []
        var suspensions: [Duration] = []
        var cancelAfterSuspensions: Int?

        var polling: ExpectationPolling {
            ExpectationPolling(
                interval: .milliseconds(100),
                now: { self.now },
                sleep: { duration in
                    self.sleeps.append(duration)
                    self.now += duration
                },
                suspend: { duration in
                    self.suspensions.append(duration)
                    self.now += duration
                    if self.suspensions.count == self.cancelAfterSuspensions {
                        throw CancellationError()
                    }
                }
            )
        }
    }

    @Test
    func withoutATimeoutTheConditionIsEvaluatedOnce() {
        let clock = ManualClock()
        var evaluations = 0

        let result = clock.polling.wait(timeout: nil as Duration?) {
            evaluations += 1
            return false
        }

        #Testing::expect(result == .notMet)
        #Testing::expect(evaluations == 1)
        #Testing::expect(clock.sleeps.isEmpty)
    }

    @Test
    func conditionThatIsAlreadyTrueDoesNotWait() {
        let clock = ManualClock()

        let result = clock.polling.wait(timeout: .seconds(5)) { true }

        #Testing::expect(result == .met)
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

        #Testing::expect(result == .met)
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

        #Testing::expect(result == .timedOut(.milliseconds(250)))
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

    @Test
    func suspendingWaitChecksAgainUntilTheConditionIsTrue() async {
        let clock = ManualClock()
        var evaluations = 0

        let result = await clock.polling.wait(timeout: .seconds(5)) {
            evaluations += 1
            return evaluations == 4
        }

        #Testing::expect(result == .met)
        #Testing::expect(clock.suspensions == Array(repeating: .milliseconds(100), count: 3))
        #Testing::expect(clock.sleeps.isEmpty)
    }

    @Test
    func suspendingWaitGivesUpWhenTheTimeoutHasPassed() async {
        let clock = ManualClock()

        let result = await clock.polling.wait(timeout: .milliseconds(250)) { false }

        #Testing::expect(result == .timedOut(.milliseconds(250)))
        #Testing::expect(clock.suspensions == [.milliseconds(100), .milliseconds(100), .milliseconds(50)])
    }

    @Test
    func suspendingWaitEndsWhenTheTaskIsCancelled() async {
        let clock = ManualClock()
        clock.cancelAfterSuspensions = 2
        var evaluations = 0

        let result = await clock.polling.wait(timeout: .seconds(5)) {
            evaluations += 1
            return false
        }

        #Testing::expect(result == .cancelled(.seconds(5)))
        #Testing::expect(evaluations == 2)
    }

    @Test
    func waitEndsWhenTheTestReachesItsTimeLimit() {
        let clock = ManualClock()
        let timeLimit = TestTimeLimit(limit: .seconds(1), deadline: clock.now + .milliseconds(250))

        let result = TestTimeLimit.$current.withValue(timeLimit) {
            clock.polling.wait(timeout: .seconds(5)) { false }
        }

        #Testing::expect(result == .timeLimitReached(.seconds(1)))
        #Testing::expect(clock.sleeps == [.milliseconds(100), .milliseconds(100), .milliseconds(50)])
    }

    @Test
    func suspendingWaitEndsWhenTheTestReachesItsTimeLimit() async {
        let clock = ManualClock()
        let timeLimit = TestTimeLimit(limit: .seconds(1), deadline: clock.now + .milliseconds(250))

        let result = await TestTimeLimit.$current.withValue(timeLimit) {
            await clock.polling.wait(timeout: .seconds(5)) { false }
        }

        #Testing::expect(result == .timeLimitReached(.seconds(1)))
        #Testing::expect(clock.suspensions == [.milliseconds(100), .milliseconds(100), .milliseconds(50)])
    }

    @Test
    func cancellationAfterTheTimeLimitIsReportedAsTheTimeLimit() async {
        let clock = ManualClock()
        clock.cancelAfterSuspensions = 2
        let timeLimit = TestTimeLimit(limit: .seconds(1), deadline: clock.now + .milliseconds(150))

        let result = await TestTimeLimit.$current.withValue(timeLimit) {
            await clock.polling.wait(timeout: .seconds(5)) { false }
        }

        #Testing::expect(result == .timeLimitReached(.seconds(1)))
    }

    @Test
    func waitWithoutATimeLimitIsUnaffected() {
        let clock = ManualClock()

        let result = clock.polling.wait(timeout: .milliseconds(250)) { false }

        #Testing::expect(result == .timedOut(.milliseconds(250)))
    }
}
