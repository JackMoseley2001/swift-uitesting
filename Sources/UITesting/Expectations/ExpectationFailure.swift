import XCTest

/// An expectation that did not hold, and where it was written.
struct ExpectationFailure: Equatable, Sendable {
    var message: String
    var filePath: String
    var line: UInt

    /// Describes a failed expectation.
    ///
    /// - Parameters:
    ///   - summary: What went wrong, such as "Expectation failed".
    ///   - expression: The source code that was checked.
    ///   - comment: The comment passed with the expectation, if any.
    ///   - timeout: How long the expectation waited, if it waited.
    ///   - difference: A description of how the two sides of a comparison differ, if known.
    static func message(
        summary: String,
        expression: String,
        comment: String?,
        timeout: Duration?,
        difference: String?
    ) -> String {
        var lines: [String]
        if let timeout {
            let seconds = timeout.timeInterval
            let unit = seconds == 1 ? "second" : "seconds"
            lines = ["\(summary) after \(String(format: "%g", seconds)) \(unit): \(expression)"]
        } else {
            lines = ["\(summary): \(expression)"]
        }
        if let comment {
            lines.append(comment)
        }
        if let difference {
            lines.append(difference)
        }
        return lines.joined(separator: "\n")
    }
}

/// Reports failed expectations to XCTest.
enum ExpectationReporter {
    /// Receives failures instead of XCTest. Unit tests set this to inspect what is reported.
    @TaskLocal static var handler: (@Sendable (ExpectationFailure) -> Void)?

    /// Records a failure of the running test at the place the expectation was written.
    static func report(message: String, filePath: StaticString, line: UInt) {
        if let handler {
            handler(ExpectationFailure(message: message, filePath: "\(filePath)", line: line))
        } else {
            XCTFail(message, file: filePath, line: line)
        }
    }
}
