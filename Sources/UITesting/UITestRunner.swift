#if canImport(Darwin)
import XCTest

/// Launches the app for a UI test and runs the test with its traits applied.
public enum UITestRunner {
    /// Launches the app with the suite's traits and the given traits, then runs a test body.
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
    /// 2. The app is launched.
    /// 3. Each trait's `setUp(_:)` runs, in the same order.
    /// 4. The test body runs.
    /// 5. Each trait's `tearDown(_:)` runs, in reverse order,
    ///    whether or not the earlier steps succeeded.
    ///
    /// - Parameters:
    ///   - suite: The test case that is running.
    ///   - traits: The traits for this test, applied after the suite's traits.
    ///   - body: The test. It receives the launched app in a ``UITestContext``.
    /// - Throws: The first error thrown by a trait or by the test body. Later errors
    ///   are recorded as failures of the test.
    @MainActor
    public static func run<Suite: UITestSuite>(
        _ suite: Suite,
        traits: [any UITestTrait] = [],
        body: @MainActor (UITestContext) async throws -> Void
    ) async throws {
        try await run(
            suite,
            traits: traits,
            makeApplication: { XCUIApplication() },
            launchApplication: { $0.launch() },
            body: body
        )
    }

    @MainActor
    static func run<Suite: UITestSuite>(
        _ suite: Suite,
        traits: [any UITestTrait],
        makeApplication: @MainActor () -> XCUIApplication,
        launchApplication: @MainActor (XCUIApplication) -> Void,
        body: @MainActor (UITestContext) async throws -> Void
    ) async throws {
        let traits = Suite.suiteTraits + traits
        let launch = try LaunchConfiguration(applying: traits)

        let app = makeApplication()
        app.launchArguments = launch.arguments
        app.launchEnvironment = launch.environment
        launchApplication(app)

        let context = UITestContext(app: app, testCase: suite, launch: launch)
        var startedTraits: [any UITestTrait] = []
        var errors: [any Error] = []

        do {
            for trait in traits {
                startedTraits.append(trait)
                try await trait.setUp(context)
            }
            try await body(context)
        } catch {
            errors.append(error)
        }

        for trait in startedTraits.reversed() {
            do {
                try await trait.tearDown(context)
            } catch {
                errors.append(error)
            }
        }

        guard let firstError = errors.first else { return }
        for error in errors.dropFirst() {
            suite.record(
                XCTIssue(type: .thrownError, compactDescription: "\(error)", associatedError: error)
            )
        }
        throw firstError
    }
}
#endif
