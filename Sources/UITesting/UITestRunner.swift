import XCTest

/// Launches the app for a UI test and runs the test with its traits applied.
public enum UITestRunner {
    /// Launches the app with the suite's traits and the given traits, then runs a test body.
    ///
    /// The ``UITest(traits:)`` macro calls this for you. Call it yourself to run a test without the macro:
    ///
    /// ```swift
    /// final class LoginTests: XCTestCase, UITestSuite {
    ///     @MainActor
    ///     func testShowsSignInButton() async throws {
    ///         try await UITestRunner.run(self, traits: [.launchArgument("--skip-onboarding")]) { context in
    ///             #expect(context.app.buttons["Sign in"].exists)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// The steps are:
    ///
    /// 1. Each trait's `prepare(_:)` configures the launch, the
    ///    suite's traits first.
    /// 2. Each trait's `willLaunch(_:)` runs, in the same order.
    /// 3. The app is launched, unless one of the traits is
    ///    ``UITestTrait/manualLaunch``.
    /// 4. Each trait's `setUp(_:)` runs, in the same order.
    /// 5. The test body runs.
    /// 6. Each trait's `tearDown(_:)` runs, in reverse order,
    ///    whether or not the earlier steps succeeded. If a trait's
    ///    `willLaunch(_:)` throws, the app is not launched, and that trait and
    ///    the ones before it are torn down.
    ///
    /// - Parameters:
    ///   - suite: The test case that is running.
    ///   - traits: The traits for this test, applied after the suite's traits.
    ///   - body: The test. It receives the app in a ``UITestContext``.
    /// - Throws: The first error thrown by a trait or by the test body. Later errors
    ///   are recorded as failures of the test. A requirement that was not met ends the
    ///   test without an error being thrown, because `#require` has already recorded it.
    @MainActor
    public static func run<Suite: UITestSuite>(
        _ suite: Suite,
        traits: [any UITestTrait] = [],
        body: @MainActor (UITestContext) async throws -> Void
    ) async throws {
        let traits = Suite.suiteTraits + traits
        let launch = try LaunchConfiguration(applying: traits)

        let app = XCUIApplication()
        app.configure(with: launch)

        let context = UITestContext(app: app, testCase: suite, launch: launch)
        let capture = FailureAttachmentsTrait.isEnabled(in: traits) ? FailureCapture(app: app, testCase: suite) : nil
        // A test with arguments is run once for each, so failures of an earlier run are not this run's.
        let failuresBefore = suite.testRun?.totalFailureCount ?? 0
        let alertRules = systemAlertRules(from: traits)
        let alertMonitor = alertRules.flatMap { answerInterruptingSystemAlerts(in: suite, with: $0) }
        defer {
            if let alertMonitor {
                suite.removeUIInterruptionMonitor(alertMonitor)
            }
        }
        try await endingOnFailedRequirement {
            try await ActionTimeout.$current.withValue(ActionTimeout.timeout(from: traits)) {
                try await RunningTest.$appUnderTest.withValue(AppUnderTest(app)) {
                    try await RunningTest.$failureCapture.withValue(capture) {
                        try await RunningTest.$systemAlertRules.withValue(alertRules) {
                            try await withSteps(
                                traits,
                                willLaunch: { try await $0.willLaunch(context) },
                                launch: {
                                    if launchesAutomatically(with: traits) {
                                        app.launch()
                                        app.waitForFirstWindow()
                                    }
                                },
                                setUp: { try await $0.setUp(context) },
                                tearDown: { try await $0.tearDown(context) },
                                recordAdditionalError: { error in
                                    suite.record(
                                        XCTIssue(
                                            type: .thrownError,
                                            compactDescription: "\(error)",
                                            associatedError: error
                                        )
                                    )
                                },
                                body: {
                                    // A failure that this library reports is captured as it happens.
                                    // This covers the others, such as XCTest's own assertions and
                                    // thrown errors, before the traits tear anything down.
                                    do {
                                        try await body(context)
                                    } catch {
                                        capture?.captureOnce()
                                        clearUpAfterFailure()
                                        throw error
                                    }
                                    if (suite.testRun?.totalFailureCount ?? 0) > failuresBefore {
                                        capture?.captureOnce()
                                        clearUpAfterFailure()
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    /// Runs a test body once for each of a collection of arguments, launching the app each time.
    ///
    /// The ``UITest(traits:arguments:)`` macro calls this for you. Each argument gets a
    /// run of its own, with every step of ``run(_:traits:body:)``: the app is launched
    /// fresh, the traits are set up, the body runs with the argument, and the traits
    /// are torn down. A failure with one argument does not stop the others from running.
    ///
    /// Each run is a step named after its argument, so a failure says which argument
    /// it happened with, such as `[fruit: Pear]`.
    ///
    /// - Parameters:
    ///   - suite: The test case that is running.
    ///   - traits: The traits for this test, applied after the suite's traits.
    ///   - arguments: The values to run the test with, in order.
    ///   - name: What an argument is, such as the name of the parameter that receives it.
    ///   - filePath: The file of the test, where an error it throws is recorded.
    ///   - line: The line of the test, where an error it throws is recorded.
    ///   - body: The test. It receives an argument, and the app in a ``UITestContext``.
    /// - Throws: `XCTSkip` if a trait skips the test. Any other error is recorded as a
    ///   failure of the test for its argument, and the remaining arguments are still run.
    @MainActor
    public static func run<Suite: UITestSuite, Arguments: Collection>(
        _ suite: Suite,
        traits: [any UITestTrait] = [],
        arguments: Arguments,
        named name: String? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        body: @MainActor (Arguments.Element, UITestContext) async throws -> Void
    ) async throws {
        try await forEachArgument(
            arguments,
            named: name,
            run: { argument in
                try await run(suite, traits: traits) { context in
                    try await body(argument, context)
                }
            },
            recordError: { description, error in
                // The error is recorded at the test, as XCTest does for an error a test throws.
                let location = XCTSourceCodeLocation(filePath: "\(filePath)", lineNumber: Int(line))
                suite.record(
                    XCTIssue(
                        type: .thrownError,
                        compactDescription: description,
                        sourceCodeContext: XCTSourceCodeContext(location: location),
                        associatedError: error
                    )
                )
            }
        )
    }

    /// Runs an operation once for each argument, as a step named after the argument.
    ///
    /// An error thrown for one argument is passed to `recordError`, with a description
    /// that names the argument, and the remaining arguments are still run. `XCTSkip` is
    /// thrown on instead, because it skips the whole test.
    @MainActor
    static func forEachArgument<Arguments: Collection>(
        _ arguments: Arguments,
        named name: String?,
        run: @MainActor (Arguments.Element) async throws -> Void,
        recordError: @MainActor (String, any Error) -> Void
    ) async throws {
        for argument in arguments {
            let label = argumentLabel(for: argument, named: name)
            do {
                try await step(label) {
                    try await run(argument)
                }
            } catch let skip as XCTSkip {
                throw skip
            } catch {
                recordError(StepPath.describing("\(error)", in: StepPath.current + [label]), error)
            }
        }
    }

    /// Returns the name of the step for one argument, such as "fruit: Pear".
    static func argumentLabel(for argument: some Any, named name: String?) -> String {
        let value = String(describing: argument)
        guard let name, !name.isEmpty, name != "_" else { return value }
        return "\(name): \(value)"
    }

    /// Returns the answers that a test's traits give to system alerts, or `nil` if they give none.
    static func systemAlertRules(from traits: [any UITestTrait]) -> SystemAlertRules? {
        let rules = traits.compactMap { ($0 as? any SystemAlertAnswering)?.systemAlertRule }
        return rules.isEmpty ? nil : SystemAlertRules(rules: rules)
    }

    /// Answers a system alert that gets in the way of an action on the app.
    ///
    /// XCTest calls the monitor when an alert blocks an action, which is the case that
    /// the check between the evaluations of a wait does not cover.
    @MainActor
    static func answerInterruptingSystemAlerts(
        in suite: XCTestCase,
        with rules: SystemAlertRules
    ) -> (any NSObjectProtocol)? {
        #if os(iOS)
            suite.addUIInterruptionMonitor(withDescription: "System alert") { alert in
                MainActor.assumeIsolated {
                    SystemAlert(element: alert).answer(with: rules)
                }
            }
        #else
            nil
        #endif
    }

    /// Leaves the device ready for the next test after one has failed.
    @MainActor
    static func clearUpAfterFailure() {
        #if os(iOS)
            SystemAlert.refuseLeftover()
        #endif
    }

    /// Returns whether the runner launches the app itself, which it does unless a trait leaves that to the test.
    static func launchesAutomatically(with traits: [any UITestTrait]) -> Bool {
        !traits.contains { $0 is ManualLaunchTrait }
    }

    /// Runs an operation, and returns normally if it ends because a requirement was not met.
    ///
    /// `#require` records the failure where it is written before it throws, so passing the
    /// error on to XCTest would report the same failure a second time.
    @MainActor
    static func endingOnFailedRequirement(_ operation: @MainActor () async throws -> Void) async throws {
        do {
            try await operation()
        } catch is RequirementFailedError {
        }
    }

    /// Runs each step's pre-launch work, launches, sets up each step, runs the body, then tears the
    /// steps down in reverse order.
    ///
    /// A step is torn down if its pre-launch work was started, even if that work, a set-up or
    /// the body threw. If pre-launch work throws, nothing is launched and no step is set up;
    /// the step that threw and the steps before it are torn down, and later steps are not.
    /// The first error is thrown, and any later error is passed to `recordAdditionalError`.
    @MainActor
    static func withSteps<Step>(
        _ steps: [Step],
        willLaunch: @MainActor (Step) async throws -> Void,
        launch: @MainActor () -> Void,
        setUp: @MainActor (Step) async throws -> Void,
        tearDown: @MainActor (Step) async throws -> Void,
        recordAdditionalError: @MainActor (any Error) -> Void,
        body: @MainActor () async throws -> Void
    ) async throws {
        var startedSteps: [Step] = []
        var errors: [any Error] = []

        do {
            for step in steps {
                startedSteps.append(step)
                try await willLaunch(step)
            }
            launch()
            for step in steps {
                try await setUp(step)
            }
            try await body()
        } catch {
            errors.append(error)
        }

        for step in startedSteps.reversed() {
            do {
                try await tearDown(step)
            } catch {
                errors.append(error)
            }
        }

        guard let firstError = errors.first else { return }
        for error in errors.dropFirst() {
            recordAdditionalError(error)
        }
        throw firstError
    }
}
