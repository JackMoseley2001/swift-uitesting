/// A trait that sets how long an element's actions wait for it to be ready.
///
/// Create one with ``UITestTrait/actionTimeout(_:)``.
public struct ActionTimeoutTrait: UITestTrait {
    /// How long actions wait.
    public let timeout: Duration
}

extension UITestTrait where Self == ActionTimeoutTrait {
    /// Sets how long actions such as ``UITestElement/tap(within:filePath:line:)`` wait for
    /// their element to be ready.
    ///
    /// Without this trait, actions wait for up to 5 seconds. On a suite, it applies to
    /// every test in the suite, and a test can give its own:
    ///
    /// ```swift
    /// @UITestSuite(traits: .actionTimeout(.seconds(2)))
    /// final class InboxTests: XCTestCase {
    ///     @UITest(traits: .actionTimeout(.seconds(20)))
    ///     func loadsAVeryLongThread(app: XCUIApplication) throws { /* ... */ }
    /// }
    /// ```
    ///
    /// One call can also wait for a different time, by passing `within:` to the action.
    ///
    /// - Parameter timeout: How long actions wait.
    public static func actionTimeout(_ timeout: Duration) -> Self {
        ActionTimeoutTrait(timeout: timeout)
    }
}

/// How long actions wait for their element, for the test that is running.
enum ActionTimeout {
    /// The time actions wait when a test has no ``ActionTimeoutTrait``.
    static let standard: Duration = .seconds(5)

    @TaskLocal static var current: Duration = standard

    /// Returns the timeout that a test's traits ask for, which is the last one given.
    static func timeout(from traits: [any UITestTrait]) -> Duration {
        traits.lazy.reversed().compactMap { ($0 as? ActionTimeoutTrait)?.timeout }.first ?? standard
    }
}
