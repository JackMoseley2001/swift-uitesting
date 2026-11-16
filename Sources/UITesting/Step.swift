import XCTest

/// Runs part of a test as a named step.
///
/// Steps are optional. They group what a test does under names that say what it is
/// for, so that a report reads as a list of steps instead of a list of taps, and a
/// failure says which step it happened in:
///
/// ```swift
/// @UITest
/// func sendsAMessage(app: XCUIApplication) throws {
///     try step("Sign in") {
///         try app[LoginID.emailField].enter("ada@example.com")
///         try app[LoginID.signInButton].tap()
///     }
///     try step("Write the message") {
///         try app[InboxID.composeButton].tap()
///         try app[ComposeID.bodyField].enter("Hello")
///     }
/// }
/// ```
///
/// A failure in the second step starts with `[Write the message]`. In Xcode's test
/// report, each step is an activity that holds what happened inside it.
///
/// Steps can be nested, and a step returns what its body returns.
///
/// - Parameters:
///   - name: What the step does, as it should read in a report.
///   - body: The work of the step.
/// - Returns: The value that `body` returns.
/// - Throws: Whatever `body` throws.
@MainActor
@discardableResult
public func step<Result>(_ name: String, _ body: () throws -> Result) rethrows -> Result {
    try StepPath.$current.withValue(StepPath.current + [name]) {
        guard StepPath.opensActivities else { return try body() }
        return try XCTContext.runActivity(named: name) { _ in
            try body()
        }
    }
}

/// Runs part of an `async` test as a named step.
///
/// This is the same as the step for a test that is not `async`, with one difference
/// in Xcode's test report: XCTest cannot keep an activity open across an `await`, so
/// the step is shown as a marker where it starts, and what happens in it follows the
/// marker instead of being held inside it. Failures still say which step they
/// happened in.
///
/// ```swift
/// try await step("Wait for the upload") {
///     try await #require(app[UploadID.doneLabel].exists, within: .seconds(30))
/// }
/// ```
///
/// - Parameters:
///   - name: What the step does, as it should read in a report.
///   - body: The work of the step.
/// - Returns: The value that `body` returns.
/// - Throws: Whatever `body` throws.
@MainActor
@discardableResult
public func step<Result>(_ name: String, _ body: @MainActor () async throws -> Result) async rethrows -> Result {
    if StepPath.opensActivities {
        XCTContext.runActivity(named: name) { _ in }
    }
    return try await StepPath.$current.withValue(StepPath.current + [name]) {
        try await body()
    }
}

/// The named steps that the running test is inside, outermost first.
enum StepPath {
    @TaskLocal static var current: [String] = []

    /// Whether a step opens an XCTest activity. Unit tests turn this off, because XCTest
    /// only allows activities inside one of its own tests.
    @TaskLocal static var opensActivities = true

    /// Returns a failure message that says which step it happened in.
    ///
    /// The steps go first, in square brackets, so that they can be seen where a report
    /// only shows the start of a message.
    static func describing(_ message: String, in steps: [String] = current) -> String {
        guard !steps.isEmpty else { return message }
        return "[\(steps.joined(separator: " › "))] \(message)"
    }
}
