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
    ///             XCTAssertTrue(context.app.buttons["Sign in"].exists)
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
    ///    whether or not the earlier steps succeeded.
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
        try await endingOnFailedRequirement {
            try await withSteps(
                traits,
                willLaunch: { try await $0.willLaunch(context) },
                launch: {
                    if launchesAutomatically(with: traits) {
                        app.launch()
                    }
                },
                setUp: { try await $0.setUp(context) },
                tearDown: { try await $0.tearDown(context) },
                recordAdditionalError: { error in
                    suite.record(
                        XCTIssue(type: .thrownError, compactDescription: "\(error)", associatedError: error)
                    )
                },
                body: { try await body(context) }
            )
        }
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
    /// A step is torn down if its set-up was started, even if the set-up or the body threw.
    /// If pre-launch work throws, nothing is launched and no step is set up or torn down.
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
                try await willLaunch(step)
            }
            launch()
            for step in steps {
                startedSteps.append(step)
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
