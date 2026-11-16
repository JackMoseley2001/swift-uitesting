/// The error thrown when a requirement made with `#require` is not met.
///
/// The failure has already been recorded against the test when this is thrown, so there
/// is no need to report it again. ``UITestRunner`` ends the test without rethrowing it.
public struct RequirementFailedError: Error, CustomStringConvertible, Sendable {
    /// A description of the requirement that was not met.
    public let message: String

    public var description: String { message }
}
