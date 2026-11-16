import XCTest

/// A trait that skips a test unless a condition holds.
///
/// Create one with ``UITestTrait/enabled(if:_:)``, ``UITestTrait/disabled(_:)`` or
/// ``UITestTrait/disabled(if:_:)``.
public struct ConditionTrait: UITestTrait {
    /// Returns whether the test should run.
    let isEnabled: @Sendable () throws -> Bool

    /// Why the test is skipped, if it is.
    public let comment: String?

    public func prepare(_ launch: inout LaunchConfiguration) throws {
        if try !isEnabled() {
            throw XCTSkip(comment)
        }
    }
}

extension UITestTrait where Self == ConditionTrait {
    /// Runs the test only if a condition is true, and skips it otherwise.
    ///
    /// The condition is evaluated when the test starts, before the app is launched.
    ///
    /// ```swift
    /// @UITest(traits: .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil, "Needs a signed-in device"))
    /// func purchasesAnItem(app: XCUIApplication) { /* ... */ }
    /// ```
    ///
    /// - Parameters:
    ///   - condition: Whether the test should run.
    ///   - comment: Why the test is skipped when the condition is false.
    public static func enabled(
        if condition: @autoclosure @escaping @Sendable () throws -> Bool,
        _ comment: String? = nil
    ) -> Self {
        ConditionTrait(isEnabled: condition, comment: comment)
    }

    /// Skips the test.
    ///
    /// - Parameter comment: Why the test is skipped.
    public static func disabled(_ comment: String? = nil) -> Self {
        ConditionTrait(isEnabled: { false }, comment: comment)
    }

    /// Skips the test if a condition is true, and runs it otherwise.
    ///
    /// The condition is evaluated when the test starts, before the app is launched.
    ///
    /// - Parameters:
    ///   - condition: Whether the test should be skipped.
    ///   - comment: Why the test is skipped when the condition is true.
    public static func disabled(
        if condition: @autoclosure @escaping @Sendable () throws -> Bool,
        _ comment: String? = nil
    ) -> Self {
        ConditionTrait(isEnabled: { try !condition() }, comment: comment)
    }
}
