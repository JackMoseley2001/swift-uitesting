import Foundation
import Testing

@testable import UITesting

/// State that belongs to the main actor, as an app's elements do in a UI test.
@MainActor
private final class Screen {
    var isLoaded = false
    var events: [String] = []
}

/// A trait that records when it starts and finishes running the test body.
private struct RecordingWrapper: UITestTrait, TestBodyWrapping {
    let name: String
    let screen: Screen

    @MainActor
    func run(
        _ body: @escaping @MainActor () async throws -> Void,
        recordFailure: @MainActor (String) -> Void
    ) async throws {
        screen.events.append("enter \(name)")
        try await body()
        screen.events.append("exit \(name)")
    }
}

/// Blocks the calling thread, as a call into the app does in a UI test.
private func block(for seconds: TimeInterval) {
    Thread.sleep(forTimeInterval: seconds)
}

@MainActor
@Suite
struct TimeLimitTests {
    private let clock = ContinuousClock()

    /// Runs a body under a time limit, and returns the failures the limit recorded.
    private func failures(
        limit: Duration,
        body: @escaping @MainActor () async throws -> Void
    ) async throws -> [String] {
        var recorded: [String] = []
        try await UITesting.TimeLimitTrait(limit: limit).run(body) { recorded.append($0) }
        return recorded
    }

    @Test
    func bodyThatFinishesInTimeRecordsNothing() async throws {
        let screen = Screen()

        let failures = try await failures(limit: .seconds(30)) {
            screen.events.append("body")
        }

        #Testing::expect(failures.isEmpty)
        #Testing::expect(screen.events == ["body"])
    }

    @Test
    func errorFromTheBodyIsThrown() async {
        await #Testing::expect(throws: TestError(message: "body")) {
            _ = try await failures(limit: .seconds(30)) {
                throw TestError(message: "body")
            }
        }
    }

    @Test
    func blockingBodyThatTakesTooLongIsReportedWhenItFinishes() async throws {
        let screen = Screen()

        let failures = try await failures(limit: .milliseconds(100)) {
            block(for: 0.3)
            screen.events.append("finished")
        }

        #Testing::expect(failures == ["The test took longer than its time limit of 0.1 seconds."])
        #Testing::expect(screen.events == ["finished"])
    }

    @Test
    func suspendedBodyIsCancelledWhenTheTimeIsUp() async throws {
        let start = clock.now

        let failures = try await failures(limit: .milliseconds(200)) {
            try await Task.sleep(for: .seconds(60))
        }

        #Testing::expect(clock.now - start < .seconds(30))
        #Testing::expect(failures == ["The test took longer than its time limit of 0.2 seconds."])
    }

    @Test
    func awaitedExpectationEndsWhenTheTimeIsUp() async throws {
        let screen = Screen()
        let start = clock.now
        var limitFailures: [String] = []

        let expectationFailures = try await reportedFailures {
            limitFailures = try await failures(limit: .milliseconds(200)) {
                await #UITestingExpect(screen.isLoaded, within: .seconds(60))
            }
        }

        #Testing::expect(clock.now - start < .seconds(30))
        #Testing::expect(limitFailures == ["The test took longer than its time limit of 0.2 seconds."])
        #Testing::expect(
            expectationFailures.map(\.message) == [
                """
                Expectation failed: screen.isLoaded
                The wait ended when the test reached its time limit of 0.2 seconds.
                """
            ]
        )
    }

    @Test
    func blockingExpectationEndsWhenTheTimeIsUp() async throws {
        let screen = Screen()
        let start = clock.now
        var limitFailures: [String] = []

        let expectationFailures = try await reportedFailures {
            limitFailures = try await failures(limit: .milliseconds(200)) {
                let waitWithoutSuspending = { #UITestingExpect(screen.isLoaded, within: .seconds(60)) }
                waitWithoutSuspending()
            }
        }

        #Testing::expect(clock.now - start < .seconds(30))
        #Testing::expect(limitFailures == ["The test took longer than its time limit of 0.2 seconds."])
        #Testing::expect(
            expectationFailures.map(\.message) == [
                """
                Expectation failed: screen.isLoaded
                The wait ended when the test reached its time limit of 0.2 seconds.
                """
            ]
        )
    }

    @Test
    func requirementEndsTheTestWhenTheTimeIsUp() async throws {
        let screen = Screen()
        var limitFailures: [String] = []
        var thrown: (any Error)?

        _ = await reportedFailures {
            do {
                limitFailures = try await failures(limit: .milliseconds(200)) {
                    try await #UITestingRequire(screen.isLoaded, within: .seconds(60))
                    screen.events.append("after the requirement")
                }
            } catch {
                thrown = error
            }
        }

        #Testing::expect(thrown is RequirementFailedError)
        #Testing::expect(screen.events.isEmpty)
        #Testing::expect(limitFailures.isEmpty)
    }

    @Test
    func shorterOfTwoLimitsApplies() async throws {
        let screen = Screen()
        let start = clock.now
        var outerFailures: [String] = []
        var innerFailures: [String] = []

        let expectationFailures = try await reportedFailures {
            outerFailures = try await failures(limit: .milliseconds(200)) {
                innerFailures = try await self.failures(limit: .seconds(60)) {
                    await #UITestingExpect(screen.isLoaded, within: .seconds(60))
                }
            }
        }

        #Testing::expect(clock.now - start < .seconds(30))
        #Testing::expect(outerFailures == ["The test took longer than its time limit of 0.2 seconds."])
        #Testing::expect(innerFailures.isEmpty)
        #Testing::expect(
            expectationFailures.map(\.message) == [
                """
                Expectation failed: screen.isLoaded
                The wait ended when the test reached its time limit of 0.2 seconds.
                """
            ]
        )
    }

    @Test
    func traitsWrapTheBodyInTheOrderTheyAreListed() async throws {
        let screen = Screen()
        let traits: [any UITestTrait] = [
            RecordingWrapper(name: "a", screen: screen),
            EmptyTrait(),
            RecordingWrapper(name: "b", screen: screen),
        ]

        let body = UITestRunner.wrapping({ screen.events.append("body") }, with: traits) { _ in }
        try await body()

        #Testing::expect(screen.events == ["enter a", "enter b", "body", "exit b", "exit a"])
    }

    @Test
    func timeLimitTraitIsCreatedWithItsLimit() {
        let trait: UITesting.TimeLimitTrait = .timeLimit(.seconds(15))

        #Testing::expect(trait.limit == .seconds(15))
    }
}
