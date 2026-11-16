import Testing

@testable import UITesting

@MainActor
@Suite
final class UITestRunnerTests {
    private var events: [String] = []
    private var additionalErrors: [TestError] = []

    private func run(
        steps: [String],
        failingSetUp: String? = nil,
        failingTearDown: String? = nil,
        body: @MainActor () async throws -> Void = {}
    ) async throws {
        try await UITestRunner.withSteps(
            steps,
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

        #expect(events == ["setUp a", "setUp b", "body", "tearDown b", "tearDown a"])
        #expect(additionalErrors.isEmpty)
    }

    @Test
    func bodyRunsWithoutSteps() async throws {
        try await run(steps: []) {
            events.append("body")
        }

        #expect(events == ["body"])
    }

    @Test
    func stepsAreTornDownWhenTheBodyThrows() async {
        let error = await thrownError {
            try await run(steps: ["a", "b"]) {
                throw TestError(message: "body")
            }
        }

        #expect(error == TestError(message: "body"))
        #expect(events == ["setUp a", "setUp b", "tearDown b", "tearDown a"])
        #expect(additionalErrors.isEmpty)
    }

    @Test
    func setUpErrorStopsLaterStepsAndTheBody() async {
        let error = await thrownError {
            try await run(steps: ["a", "b", "c"], failingSetUp: "b") {
                events.append("body")
            }
        }

        #expect(error == TestError(message: "setUp b"))
        #expect(events == ["setUp a", "setUp b", "tearDown b", "tearDown a"])
    }

    @Test
    func tearDownErrorIsThrownWhenNothingElseFailed() async {
        let error = await thrownError {
            try await run(steps: ["a", "b"], failingTearDown: "b")
        }

        #expect(error == TestError(message: "tearDown b"))
        #expect(events == ["setUp a", "setUp b", "tearDown b", "tearDown a"])
        #expect(additionalErrors.isEmpty)
    }

    @Test
    func tearDownErrorIsRecordedWhenTheBodyAlsoThrows() async {
        let error = await thrownError {
            try await run(steps: ["a"], failingTearDown: "a") {
                throw TestError(message: "body")
            }
        }

        #expect(error == TestError(message: "body"))
        #expect(additionalErrors == [TestError(message: "tearDown a")])
    }
}
