#if canImport(Darwin)
import XCTest

@testable import UITesting

@MainActor
final class UITestRunnerTests: XCTestCase {
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

    func testStepsAreSetUpInOrderAndTornDownInReverse() async throws {
        try await run(steps: ["a", "b"]) {
            events.append("body")
        }

        XCTAssertEqual(events, ["setUp a", "setUp b", "body", "tearDown b", "tearDown a"])
        XCTAssertEqual(additionalErrors, [])
    }

    func testBodyRunsWithoutSteps() async throws {
        try await run(steps: []) {
            events.append("body")
        }

        XCTAssertEqual(events, ["body"])
    }

    func testStepsAreTornDownWhenTheBodyThrows() async {
        let error = await thrownError {
            try await run(steps: ["a", "b"]) {
                throw TestError(message: "body")
            }
        }

        XCTAssertEqual(error, TestError(message: "body"))
        XCTAssertEqual(events, ["setUp a", "setUp b", "tearDown b", "tearDown a"])
        XCTAssertEqual(additionalErrors, [])
    }

    func testSetUpErrorStopsLaterStepsAndTheBody() async {
        let error = await thrownError {
            try await run(steps: ["a", "b", "c"], failingSetUp: "b") {
                events.append("body")
            }
        }

        XCTAssertEqual(error, TestError(message: "setUp b"))
        XCTAssertEqual(events, ["setUp a", "setUp b", "tearDown b", "tearDown a"])
    }

    func testTearDownErrorIsThrownWhenNothingElseFailed() async {
        let error = await thrownError {
            try await run(steps: ["a", "b"], failingTearDown: "b")
        }

        XCTAssertEqual(error, TestError(message: "tearDown b"))
        XCTAssertEqual(events, ["setUp a", "setUp b", "tearDown b", "tearDown a"])
        XCTAssertEqual(additionalErrors, [])
    }

    func testTearDownErrorIsRecordedWhenTheBodyAlsoThrows() async {
        let error = await thrownError {
            try await run(steps: ["a"], failingTearDown: "a") {
                throw TestError(message: "body")
            }
        }

        XCTAssertEqual(error, TestError(message: "body"))
        XCTAssertEqual(additionalErrors, [TestError(message: "tearDown a")])
    }
}
#endif
