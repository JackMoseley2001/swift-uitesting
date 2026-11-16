internal import CustomDump

/// The checks behind `#expect` and `#require`. Each returns a description of the failure,
/// or `nil` if the check passed.
///
/// Every check has two forms. The first evaluates once, or blocks the calling thread
/// while it waits. The second is `async`, and suspends the task while it waits.
enum ExpectationCheck {
    static func condition(
        _ condition: () throws -> Bool,
        summary: String,
        expression: String,
        comment: () -> String?,
        timeout: Duration?
    ) rethrows -> String? {
        let outcome = try ExpectationPolling().wait(timeout: timeout, until: condition)
        return failure(summary: summary, expression: expression, comment: comment, outcome: outcome)
    }

    static func condition(
        _ condition: () throws -> Bool,
        summary: String,
        expression: String,
        comment: () -> String?,
        timeout: Duration,
        isolation: isolated (any Actor)? = #isolation
    ) async rethrows -> String? {
        let outcome = try await ExpectationPolling().wait(timeout: timeout, until: condition)
        return failure(summary: summary, expression: expression, comment: comment, outcome: outcome)
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
        let outcome = try ExpectationPolling().wait(timeout: timeout) {
            let pair = (try lhs(), try rhs())
            values = pair
            return try isEqual(pair.0, pair.1)
        }
        return failure(
            summary: summary,
            expression: expression,
            comment: comment,
            outcome: outcome,
            difference: values.flatMap { difference($0.0, $0.1) }
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
        timeout: Duration,
        isolation: isolated (any Actor)? = #isolation
    ) async rethrows -> String? {
        var values: (LHS, RHS)?
        let outcome = try await ExpectationPolling().wait(timeout: timeout) {
            let pair = (try lhs(), try rhs())
            values = pair
            return try isEqual(pair.0, pair.1)
        }
        return failure(
            summary: summary,
            expression: expression,
            comment: comment,
            outcome: outcome,
            difference: values.flatMap { difference($0.0, $0.1) }
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
        let outcome = try ExpectationPolling().wait(timeout: timeout) {
            found = try value()
            return found != nil
        }
        return result(found, summary: summary, expression: expression, comment: comment, outcome: outcome)
    }

    /// Returns the value, or a description of the failure if there was none.
    static func value<Value>(
        _ value: () throws -> Value?,
        summary: String,
        expression: String,
        comment: () -> String?,
        timeout: Duration,
        isolation: isolated (any Actor)? = #isolation
    ) async rethrows -> Result<Value, RequirementFailedError> {
        var found: Value?
        let outcome = try await ExpectationPolling().wait(timeout: timeout) {
            found = try value()
            return found != nil
        }
        return result(found, summary: summary, expression: expression, comment: comment, outcome: outcome)
    }

    private static func failure(
        summary: String,
        expression: String,
        comment: () -> String?,
        outcome: WaitOutcome,
        difference: @autoclosure () -> String? = nil
    ) -> String? {
        guard outcome != .met else { return nil }

        return ExpectationFailure.message(
            summary: summary,
            expression: expression,
            comment: comment(),
            outcome: outcome,
            difference: difference()
        )
    }

    private static func result<Value>(
        _ found: Value?,
        summary: String,
        expression: String,
        comment: () -> String?,
        outcome: WaitOutcome
    ) -> Result<Value, RequirementFailedError> {
        if let found {
            return .success(found)
        }
        let message = ExpectationFailure.message(
            summary: summary,
            expression: expression,
            comment: comment(),
            outcome: outcome,
            difference: nil
        )
        return .failure(RequirementFailedError(message: message))
    }
}

// A comparison is written with the value being checked on the left and the value it should
// have on the right. A difference is shown from the expected value to the actual one, so
// lines starting with "-" are what was expected and lines starting with "+" are what was
// found. That is why `diff` is given the right-hand side first.
//
// The functions below are what `#expect` and `#require` expand into. They are public so
// that the expanded code can call them, and are not meant to be called directly.
//
// Each has an `async` form that takes a timeout. In an `async` function the compiler
// chooses that form for a call with a timeout, so the wait suspends the task. Everywhere
// else it chooses the first form, which blocks while it waits.

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

/// Checks a condition for `#expect`, and reports a failure if it does not hold, suspending the task while it waits.
@_documentation(visibility: private)
public func __expect(
    _ condition: () throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration,
    isolation: isolated (any Actor)? = #isolation,
    filePath: StaticString,
    line: UInt
) async rethrows {
    let failure = try await ExpectationCheck.condition(
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
        difference: { diff($1, $0) },
        summary: "Expectation failed",
        expression: expression,
        comment: comment,
        timeout: timeout
    )
    if let failure {
        ExpectationReporter.report(message: failure, filePath: filePath, line: line)
    }
}

/// Checks that two values are equal for `#expect`, and reports how they differ if they are not, suspending the task while it waits.
@_documentation(visibility: private)
public func __expectEqual<Value>(
    _ lhs: () throws -> Value,
    _ rhs: () throws -> Value,
    _ isEqual: (Value, Value) throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration,
    isolation: isolated (any Actor)? = #isolation,
    filePath: StaticString,
    line: UInt
) async rethrows {
    let failure = try await ExpectationCheck.equality(
        lhs,
        rhs,
        isEqual,
        difference: { diff($1, $0) },
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
        difference: { diff($1 as Any, $0 as Any) },
        summary: "Expectation failed",
        expression: expression,
        comment: comment,
        timeout: timeout
    )
    if let failure {
        ExpectationReporter.report(message: failure, filePath: filePath, line: line)
    }
}

/// Checks that two values of different types are equal for `#expect`, suspending the task while it waits.
@_documentation(visibility: private)
@_disfavoredOverload
public func __expectEqual<LHS, RHS>(
    _ lhs: () throws -> LHS,
    _ rhs: () throws -> RHS,
    _ isEqual: (LHS, RHS) throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration,
    isolation: isolated (any Actor)? = #isolation,
    filePath: StaticString,
    line: UInt
) async rethrows {
    let failure = try await ExpectationCheck.equality(
        lhs,
        rhs,
        isEqual,
        difference: { diff($1 as Any, $0 as Any) },
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

/// Checks a condition for `#require`, and reports a failure and throws if it does not hold, suspending the task while it waits.
@_documentation(visibility: private)
public func __require(
    _ condition: () throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration,
    isolation: isolated (any Actor)? = #isolation,
    filePath: StaticString,
    line: UInt
) async throws {
    let failure = try await ExpectationCheck.condition(
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
        difference: { diff($1, $0) },
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
/// if they are not, suspending the task while it waits.
@_documentation(visibility: private)
public func __requireEqual<Value>(
    _ lhs: () throws -> Value,
    _ rhs: () throws -> Value,
    _ isEqual: (Value, Value) throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration,
    isolation: isolated (any Actor)? = #isolation,
    filePath: StaticString,
    line: UInt
) async throws {
    let failure = try await ExpectationCheck.equality(
        lhs,
        rhs,
        isEqual,
        difference: { diff($1, $0) },
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
        difference: { diff($1 as Any, $0 as Any) },
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

/// Checks that two values of different types are equal for `#require`, suspending the task while it waits.
@_documentation(visibility: private)
@_disfavoredOverload
public func __requireEqual<LHS, RHS>(
    _ lhs: () throws -> LHS,
    _ rhs: () throws -> RHS,
    _ isEqual: (LHS, RHS) throws -> Bool,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration,
    isolation: isolated (any Actor)? = #isolation,
    filePath: StaticString,
    line: UInt
) async throws {
    let failure = try await ExpectationCheck.equality(
        lhs,
        rhs,
        isEqual,
        difference: { diff($1 as Any, $0 as Any) },
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

/// Returns an optional value for `#require`, or reports a failure and throws if it is `nil`, suspending the task while it waits.
@_documentation(visibility: private)
public func __requireValue<Value>(
    _ value: () throws -> Value?,
    expression: String,
    comment: @autoclosure () -> String? = nil,
    timeout: Duration,
    isolation: isolated (any Actor)? = #isolation,
    filePath: StaticString,
    line: UInt
) async throws -> Value {
    let result = try await ExpectationCheck.value(
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
