import XCTest

/// An expectation that did not hold, and where it was written.
struct ExpectationFailure: Equatable, Sendable {
    var message: String
    var filePath: String
    var line: UInt

    /// Says what the markers in a difference mean. It is shown above every difference.
    static let differenceLegend = "(- expected, + actual)"

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
            lines = ["\(summary) after \(describe(timeout)): \(expression)"]
        case .cancelled(let timeout):
            lines = [
                "\(summary): \(expression)",
                "The wait was cancelled before its timeout of \(describe(timeout)) had passed.",
            ]
        case .met, .notMet:
            lines = ["\(summary): \(expression)"]
        }
        if let comment {
            lines.append(comment)
        }
        if let difference {
            lines.append(differenceLegend)
            lines.append(difference)
        }
        return lines.joined(separator: "\n")
    }

    /// Describes a duration in seconds, such as "5 seconds".
    static func describe(_ duration: Duration) -> String {
        let seconds = duration.timeInterval
        return "\(String(format: "%g", seconds)) \(seconds == 1 ? "second" : "seconds")"
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
