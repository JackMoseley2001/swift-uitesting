/// A trait that fails a test if its body takes longer than a time limit.
///
/// Create one with ``UITestTrait/timeLimit(_:)``.
public struct TimeLimitTrait: UITestTrait, TestBodyWrapping {
    /// How long the body of the test may take.
    public let limit: Duration

    @MainActor
    func run(
        _ body: @escaping @MainActor () async throws -> Void,
        recordFailure: @MainActor (String) -> Void
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now + limit

        // A shorter limit set by a trait further out still applies.
        var timeLimit = TestTimeLimit(limit: limit, deadline: deadline)
        if let outer = TestTimeLimit.current, outer.deadline < deadline {
            timeLimit = outer
        }

        // The body runs in its own task so that it can be cancelled when the time is up.
        let test = Task { @MainActor in
            try await TestTimeLimit.$current.withValue(timeLimit) {
                try await body()
            }
        }
        let watchdog = Task {
            try await Task.sleep(until: deadline, clock: clock)
            test.cancel()
        }
        let result = await withTaskCancellationHandler {
            await test.result
        } onCancel: {
            test.cancel()
        }
        watchdog.cancel()

        let tookTooLong = clock.now >= deadline
        if tookTooLong {
            recordFailure("The test took longer than its time limit of \(limit.describedInSeconds).")
        }

        do {
            try result.get()
        } catch is CancellationError where tookTooLong {
            // The body stopped because this trait cancelled it, which is already recorded.
        }
    }
}

extension UITestTrait where Self == TimeLimitTrait {
    /// Fails the test if its body takes longer than the given time.
    ///
    /// The limit covers the body of the test. It does not include launching the app or
    /// the set-up of other traits.
    ///
    /// ```swift
    /// @UITest(traits: .timeLimit(.seconds(15)))
    /// func loadsTheFeed(app: XCUIApplication) async throws {
    ///     try await #require(app.cells.firstMatch.exists, within: .seconds(30))
    /// }
    /// ```
    ///
    /// When the time is up:
    ///
    /// - A failure is recorded against the test.
    /// - A wait in `#expect` or `#require` ends, and reports that the time limit was reached.
    /// - The test's task is cancelled, so other suspended work that responds to
    ///   cancellation ends too.
    ///
    /// A call that is blocking the test cannot be interrupted. Tapping an element, reading
    /// one, and `waitForExistence(timeout:)` all run to completion, so such a test is
    /// reported as over its limit only once that call returns.
    ///
    /// When a suite and a test both have a time limit, the shorter one applies.
    ///
    /// - Parameter limit: How long the body of the test may take.
    public static func timeLimit(_ limit: Duration) -> Self {
        TimeLimitTrait(limit: limit)
    }
}
