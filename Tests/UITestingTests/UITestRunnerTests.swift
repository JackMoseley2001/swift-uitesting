#if canImport(Darwin)
import XCTest

@testable import UITesting

final class UITestRunnerTests: XCTestCase, UITestSuite {
    static var suiteTraits: [any UITestTrait] {
        [.launchArgument("--suite"), .environment("SCOPE", "suite")]
    }

    private let log = EventLog()

    @MainActor
    private func run(
        traits: [any UITestTrait],
        body: @MainActor (UITestContext) async throws -> Void = { _ in }
    ) async throws {
        try await UITestRunner.run(
            self,
            traits: traits,
            makeApplication: { XCUIApplication(bundleIdentifier: "com.example.UITestingTests") },
            launchApplication: { [log] app in
                log.record("launch \(app.launchArguments) \(app.launchEnvironment["SCOPE"] ?? "nil")")
            },
            body: body
        )
    }

    private func trait(_ name: String) -> RecordingTrait {
        RecordingTrait(name: name, log: log)
    }

    @MainActor
    func testStepsRunInOrder() async throws {
        try await run(traits: [trait("a"), trait("b")]) { [log] _ in
            log.record("body")
        }

        XCTAssertEqual(log.events, [
            "prepare a",
            "prepare b",
            #"launch ["--suite"] suite"#,
            "setUp a",
            "setUp b",
            "body",
            "tearDown b",
            "tearDown a",
        ])
    }

    @MainActor
    func testSuiteTraitsAreAppliedBeforeTheTestsTraits() async throws {
        try await run(traits: [.launchArgument("--test"), .environment("SCOPE", "test")]) { context in
            XCTAssertEqual(context.launch.arguments, ["--suite", "--test"])
            XCTAssertEqual(context.launch.environment["SCOPE"], "test")
        }

        XCTAssertEqual(log.events, [#"launch ["--suite", "--test"] test"#])
    }

    @MainActor
    func testContextDescribesTheRunningTest() async throws {
        try await run(traits: []) { context in
            XCTAssertTrue(context.testCase === self)
            XCTAssertEqual(context.app.launchArguments, context.launch.arguments)
            XCTAssertEqual(context.app.launchEnvironment, context.launch.environment)
            XCTAssertTrue(LaunchTraits(environment: context.launch.environment).isUITesting)
        }
    }

    @MainActor
    func testTearDownRunsWhenTheBodyThrows() async {
        do {
            try await run(traits: [trait("a")]) { _ in
                throw TestError(message: "body")
            }
            XCTFail("Expected an error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, TestError(message: "body"))
        }

        XCTAssertEqual(log.events.suffix(2), ["setUp a", "tearDown a"])
    }

    @MainActor
    func testSetUpErrorStopsLaterTraitsAndTheBody() async {
        var failing = trait("b")
        failing.setUpError = TestError(message: "setUp")

        do {
            try await run(traits: [trait("a"), failing, trait("c")]) { [log] _ in
                log.record("body")
            }
            XCTFail("Expected an error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, TestError(message: "setUp"))
        }

        XCTAssertEqual(log.events.suffix(4), ["setUp a", "setUp b", "tearDown b", "tearDown a"])
    }

    @MainActor
    func testTearDownErrorIsThrownWhenTheBodySucceeds() async {
        var failing = trait("a")
        failing.tearDownError = TestError(message: "tearDown")

        do {
            try await run(traits: [failing, trait("b")])
            XCTFail("Expected an error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, TestError(message: "tearDown"))
        }

        XCTAssertEqual(log.events.suffix(2), ["tearDown b", "tearDown a"])
    }

    @MainActor
    func testTearDownErrorIsRecordedWhenTheBodyAlsoThrows() async {
        var failing = trait("a")
        failing.tearDownError = TestError(message: "tearDown")

        XCTExpectFailure("The tear down error is recorded as a failure of the test.")
        do {
            try await run(traits: [failing]) { _ in
                throw TestError(message: "body")
            }
            XCTFail("Expected an error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, TestError(message: "body"))
        }
    }

    @MainActor
    func testPrepareErrorPreventsTheLaunch() async {
        var failing = trait("a")
        failing.prepareError = TestError(message: "prepare")

        do {
            try await run(traits: [failing])
            XCTFail("Expected an error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, TestError(message: "prepare"))
        }

        XCTAssertEqual(log.events, ["prepare a"])
    }
}
#endif
