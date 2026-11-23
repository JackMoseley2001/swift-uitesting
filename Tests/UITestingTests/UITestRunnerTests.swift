import Testing

@testable import UITesting

@MainActor
@Suite
final class UITestRunnerTests {
    private var events: [String] = []
    private var additionalErrors: [TestError] = []

    private func run(
        steps: [String],
        failingWillLaunch: String? = nil,
        failingSetUp: String? = nil,
        failingTearDown: String? = nil,
        body: @MainActor () async throws -> Void = {}
    ) async throws {
        try await UITestRunner.withSteps(
            steps,
            willLaunch: { step in
                events.append("willLaunch \(step)")
                if step == failingWillLaunch { throw TestError(message: "willLaunch \(step)") }
            },
            launch: {
                events.append("launch")
            },
            setUp: { step in
                events.append("setUp \(step)")
                if step == failingSetUp { throw TestError(message: "setUp \(step)") }
            },
            tearDown: { step in
                events.append("tearDown \(step)")
                if step == failingTearDown { throw TestError(message: "tearDown \(step)") }
            },
            recordAdditionalError: { error in
                additionalErrors.append(error as? TestError ?? TestError(message: "\(error)"))
            },
            body: body
        )
    }

    private func thrownError(_ operation: () async throws -> Void) async -> TestError? {
        do {
            try await operation()
            return nil
        } catch {
            return error as? TestError ?? TestError(message: "\(error)")
        }
    }

    @Test
    func stepsAreSetUpInOrderAndTornDownInReverse() async throws {
        try await run(steps: ["a", "b"]) {
            events.append("body")
        }

        #Testing::expect(
            events == [
                "willLaunch a", "willLaunch b", "launch",
                "setUp a", "setUp b", "body", "tearDown b", "tearDown a"
            ]
        )
        #Testing::expect(additionalErrors.isEmpty)
    }

    @Test
    func bodyRunsWithoutSteps() async throws {
        try await run(steps: []) {
            events.append("body")
        }

        #Testing::expect(events == ["launch", "body"])
    }

    @Test
    func stepsAreTornDownWhenTheBodyThrows() async {
        let error = await thrownError {
            try await run(steps: ["a", "b"]) {
                throw TestError(message: "body")
            }
        }

        #Testing::expect(error == TestError(message: "body"))
        #Testing::expect(
            events == ["willLaunch a", "willLaunch b", "launch", "setUp a", "setUp b", "tearDown b", "tearDown a"]
        )
        #Testing::expect(additionalErrors.isEmpty)
    }

    @Test
    func setUpErrorStopsLaterStepsAndTheBody() async {
        let error = await thrownError {
            try await run(steps: ["a", "b", "c"], failingSetUp: "b") {
                events.append("body")
            }
        }

        #Testing::expect(error == TestError(message: "setUp b"))
        #Testing::expect(
            events == [
                "willLaunch a", "willLaunch b", "willLaunch c", "launch",
                "setUp a", "setUp b", "tearDown c", "tearDown b", "tearDown a"
            ]
        )
    }

    @Test
    func everyStepRunsItsPreLaunchWorkBeforeTheLaunch() async throws {
        try await run(steps: ["a", "b", "c"])

        #Testing::expect(events.prefix(4) == ["willLaunch a", "willLaunch b", "willLaunch c", "launch"])
    }

    @Test
    func preLaunchErrorStopsTheLaunchAndTearsDownTheStepsThatStarted() async {
        let error = await thrownError {
            try await run(steps: ["a", "b", "c"], failingWillLaunch: "b") {
                events.append("body")
            }
        }

        #Testing::expect(error == TestError(message: "willLaunch b"))
        #Testing::expect(events == ["willLaunch a", "willLaunch b", "tearDown b", "tearDown a"])
        #Testing::expect(additionalErrors.isEmpty)
    }

    @Test
    func tearDownErrorIsRecordedWhenPreLaunchWorkAlsoThrows() async {
        let error = await thrownError {
            try await run(steps: ["a", "b"], failingWillLaunch: "b", failingTearDown: "a")
        }

        #Testing::expect(error == TestError(message: "willLaunch b"))
        #Testing::expect(events == ["willLaunch a", "willLaunch b", "tearDown b", "tearDown a"])
        #Testing::expect(additionalErrors == [TestError(message: "tearDown a")])
    }

    @Test
    func tearDownErrorIsThrownWhenNothingElseFailed() async {
        let error = await thrownError {
            try await run(steps: ["a", "b"], failingTearDown: "b")
        }

        #Testing::expect(error == TestError(message: "tearDown b"))
        #Testing::expect(
            events == ["willLaunch a", "willLaunch b", "launch", "setUp a", "setUp b", "tearDown b", "tearDown a"]
        )
        #Testing::expect(additionalErrors.isEmpty)
    }

    @Test
    func tearDownErrorIsRecordedWhenTheBodyAlsoThrows() async {
        let error = await thrownError {
            try await run(steps: ["a"], failingTearDown: "a") {
                throw TestError(message: "body")
            }
        }

        #Testing::expect(error == TestError(message: "body"))
        #Testing::expect(additionalErrors == [TestError(message: "tearDown a")])
    }
}
