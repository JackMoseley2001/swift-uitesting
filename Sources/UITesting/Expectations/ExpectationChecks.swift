internal import CustomDump

/// The checks behind `#expect` and `#require`. Each returns a description of the failure,
/// or `nil` if the check passed.
enum ExpectationCheck {
    static func condition(
        _ condition: () throws -> Bool,
        summary: String,
        expression: String,
        comment: () -> String?,
        timeout: Duration?
    ) rethrows -> String? {
        guard try !ExpectationPolling().wait(timeout: timeout, until: condition) else { return nil }

        return ExpectationFailure.message(
            summary: summary,
            expression: expression,
            comment: comment(),
            timeout: timeout,
            difference: nil
        )
    }

    static func equality<LHS, RHS>(
        _ lhs: () throws -> LHS,
        _ rhs: () throws -> RHS,
        _ isEqual: (LHS, RHS) throws -> Bool,
        difference: (LHS, RHS) -> String?,
        summary: String,
        expression: String,
        comment: () -> String?,
        timeout: Duration?
    ) rethrows -> String? {
        var values: (LHS, RHS)?
        let isTrue = try ExpectationPolling().wait(timeout: timeout) {
            let pair = (try lhs(), try rhs())
            values = pair
            return try isEqual(pair.0, pair.1)
        }
        guard !isTrue, let values else { return nil }

        return ExpectationFailure.message(
            summary: summary,
            expression: expression,
            comment: comment(),
            timeout: timeout,
            difference: difference(values.0, values.1)
        )
    }

    /// Returns the value, or a description of the failure if there was none.
    static func value<Value>(
        _ value: () throws -> Value?,
        summary: String,
        expression: String,
        comment: () -> String?,
        timeout: Duration?
    ) rethrows -> Result<Value, RequirementFailedError> {
        var found: Value?
        _ = try ExpectationPolling().wait(timeout: timeout) {
            found = try value()
            return found != nil
        }
        if let found {
            return .success(found)
        }

        return .failure(
            RequirementFailedError(
                message: ExpectationFailure.message(
                    summary: summary,
                    expression: expression,
                    comment: comment(),
                    timeout: timeout,
                    difference: nil
                )
            )
        )
    }
}

// The functions below are what `#expect` and `#require` expand into. They are public so
// that the expanded code can call them, and are not meant to be called directly.

/// Checks a condition for `#expect`, and reports a failure if it does not hold.
@_documentation(visibility: private)
public func __expect(
    _ condition: () throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration? = nil,
    filePath: StaticString,
    line: UInt
) rethrows {
    let failure = try ExpectationCheck.condition(
        condition,
        summary: "Expectation failed",
        expression: expression,
        comment: comment,
        timeout: timeout
    )
    if let failure {
        ExpectationReporter.report(message: failure, filePath: filePath, line: line)
    }
}

/// Checks that two values are equal for `#expect`, and reports how they differ if they are not.
@_documentation(visibility: private)
public func __expectEqual<Value>(
    _ lhs: () throws -> Value,
    _ rhs: () throws -> Value,
    _ isEqual: (Value, Value) throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration? = nil,
    filePath: StaticString,
    line: UInt
) rethrows {
    let failure = try ExpectationCheck.equality(
        lhs,
        rhs,
        isEqual,
        difference: { diff($0, $1) },
        summary: "Expectation failed",
        expression: expression,
        comment: comment,
        timeout: timeout
    )
    if let failure {
        ExpectationReporter.report(message: failure, filePath: filePath, line: line)
    }
}

/// Checks that two values of different types are equal for `#expect`.
@_documentation(visibility: private)
@_disfavoredOverload
public func __expectEqual<LHS, RHS>(
    _ lhs: () throws -> LHS,
    _ rhs: () throws -> RHS,
    _ isEqual: (LHS, RHS) throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration? = nil,
    filePath: StaticString,
    line: UInt
) rethrows {
    let failure = try ExpectationCheck.equality(
        lhs,
        rhs,
        isEqual,
        difference: { diff($0 as Any, $1 as Any) },
        summary: "Expectation failed",
        expression: expression,
        comment: comment,
        timeout: timeout
    )
    if let failure {
        ExpectationReporter.report(message: failure, filePath: filePath, line: line)
    }
}

/// Checks a condition for `#require`, and reports a failure and throws if it does not hold.
@_documentation(visibility: private)
public func __require(
    _ condition: () throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration? = nil,
    filePath: StaticString,
    line: UInt
) throws {
    let failure = try ExpectationCheck.condition(
        condition,
        summary: "Requirement failed",
        expression: expression,
        comment: comment,
        timeout: timeout
    )
    if let failure {
        ExpectationReporter.report(message: failure, filePath: filePath, line: line)
        throw RequirementFailedError(message: failure)
    }
}

/// Checks that two values are equal for `#require`, and reports how they differ and throws
/// if they are not.
@_documentation(visibility: private)
public func __requireEqual<Value>(
    _ lhs: () throws -> Value,
    _ rhs: () throws -> Value,
    _ isEqual: (Value, Value) throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration? = nil,
    filePath: StaticString,
    line: UInt
) throws {
    let failure = try ExpectationCheck.equality(
        lhs,
        rhs,
        isEqual,
        difference: { diff($0, $1) },
        summary: "Requirement failed",
        expression: expression,
        comment: comment,
        timeout: timeout
    )
    if let failure {
        ExpectationReporter.report(message: failure, filePath: filePath, line: line)
        throw RequirementFailedError(message: failure)
    }
}

/// Checks that two values of different types are equal for `#require`.
@_documentation(visibility: private)
@_disfavoredOverload
public func __requireEqual<LHS, RHS>(
    _ lhs: () throws -> LHS,
    _ rhs: () throws -> RHS,
    _ isEqual: (LHS, RHS) throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration? = nil,
    filePath: StaticString,
    line: UInt
) throws {
    let failure = try ExpectationCheck.equality(
        lhs,
        rhs,
        isEqual,
        difference: { diff($0 as Any, $1 as Any) },
        summary: "Requirement failed",
        expression: expression,
        comment: comment,
        timeout: timeout
    )
    if let failure {
        ExpectationReporter.report(message: failure, filePath: filePath, line: line)
        throw RequirementFailedError(message: failure)
    }
}

/// Returns an optional value for `#require`, or reports a failure and throws if it is `nil`.
@_documentation(visibility: private)
public func __requireValue<Value>(
    _ value: () throws -> Value?,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration? = nil,
    filePath: StaticString,
    line: UInt
) throws -> Value {
    let result = try ExpectationCheck.value(
        value,
        summary: "Required value was nil",
        expression: expression,
        comment: comment,
        timeout: timeout
    )
    switch result {
    case .success(let value):
        return value
    case .failure(let error):
        ExpectationReporter.report(message: error.message, filePath: filePath, line: line)
        throw error
    }
}
