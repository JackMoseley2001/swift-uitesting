import Testing

@testable import UITesting

/// State that belongs to the main actor, as an app's elements do in a UI test.
@MainActor
private final class Screen {
    var isLoaded = false
    var title: String?
}

@MainActor
@Suite
struct AsyncWaitingTests {
    @Test
    func otherMainActorWorkRunsWhileAnExpectationWaits() async {
        let screen = Screen()
        Task { screen.isLoaded = true }

        let failures = await reportedFailures {
            await #UITestingExpect(screen.isLoaded, within: .seconds(5))
        }

        #Testing::expect(failures.isEmpty)
    }

    @Test
    func otherMainActorWorkRunsWhileAComparisonWaits() async {
        let screen = Screen()
        Task { screen.title = "Home" }

        let failures = await reportedFailures {
            await #UITestingExpect(screen.title == "Home", within: .seconds(5))
        }

        #Testing::expect(failures.isEmpty)
    }

    @Test
    func otherMainActorWorkRunsWhileARequirementWaits() async throws {
        let screen = Screen()
        Task {
            screen.isLoaded = true
            screen.title = "Home"
        }

        try await #UITestingRequire(screen.isLoaded, within: .seconds(5))
        try await #UITestingRequire(screen.title == "Home", within: .seconds(5))
        let title = try await #UITestingRequire(screen.title, within: .seconds(5))

        #Testing::expect(title == "Home")
    }

    @Test
    func expectationThatIsNeverMetReportsTheTimeout() async {
        let screen = Screen()

        let failures = await reportedFailures {
            await #UITestingExpect(screen.isLoaded, "after loading", within: .milliseconds(250))
        }

        #Testing::expect(
            failures.map(\.message) == ["Expectation failed after 0.25 seconds: screen.isLoaded\nafter loading"]
        )
    }

    @Test
    func requirementThatIsNeverMetIsReportedAndThrown() async {
        let screen = Screen()
        var thrown: (any Error)?

        let failures = await reportedFailures {
            do {
                _ = try await #UITestingRequire(screen.title, within: .milliseconds(250))
            } catch {
                thrown = error
            }
        }

        #Testing::expect(failures.map(\.message) == ["Required value was nil after 0.25 seconds: screen.title"])
        #Testing::expect(thrown is RequirementFailedError)
    }

    @Test
    func cancellingTheTaskEndsTheWait() async {
        let screen = Screen()
        let clock = ContinuousClock()
        let start = clock.now

        let task = Task {
            await reportedFailures {
                await #UITestingExpect(screen.isLoaded, within: .seconds(60))
            }
        }
        task.cancel()
        let failures = await task.value

        #Testing::expect(clock.now - start < .seconds(30))
        #Testing::expect(
            failures.map(\.message) == [
                """
                Expectation failed: screen.isLoaded
                The wait was cancelled before its timeout of 60 seconds had passed.
                """
            ]
        )
    }

    @Test
    func checkWithoutATimeoutNeedsNoAwaitInAnAsyncFunction() async throws {
        let screen = Screen()
        screen.title = "Home"
        await Task.yield()

        #UITestingExpect(!screen.isLoaded)
        #UITestingExpect(screen.title == "Home")
        try #UITestingRequire(!screen.isLoaded)
        let title = try #UITestingRequire(screen.title)

        #Testing::expect(title == "Home")
    }

    @Test
    func synchronousFunctionStillBlocksWhileItWaits() {
        let screen = Screen()
        Task { screen.isLoaded = true }

        let failures = reportedFailures {
            #UITestingExpect(screen.isLoaded, within: .milliseconds(250))
        }

        #Testing::expect(failures.map(\.message) == ["Expectation failed after 0.25 seconds: screen.isLoaded"])
    }
}
