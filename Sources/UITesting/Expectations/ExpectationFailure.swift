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
    ///   - outcome: How the check ended.
    ///   - difference: A description of how the two sides of a comparison differ, if known.
    static func message(
        summary: String,
        expression: String,
        comment: String?,
        outcome: WaitOutcome,
        difference: String?
    ) -> String {
        var lines: [String]
        switch outcome {
        case .timedOut(let timeout):
            lines = ["\(summary) after \(timeout.describedInSeconds): \(expression)"]
        case .cancelled(let timeout):
            lines = [
                "\(summary): \(expression)",
                "The wait was cancelled before its timeout of \(timeout.describedInSeconds) had passed.",
            ]
        case .timeLimitReached(let limit):
            lines = [
                "\(summary): \(expression)",
                "The wait ended when the test reached its time limit of \(limit.describedInSeconds).",
            ]
        case .met, .notMet:
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
