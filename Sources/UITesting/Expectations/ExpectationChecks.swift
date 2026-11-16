internal import CustomDump

// The functions in this file are what `#expect` expands into. They are public so that
// the expanded code can call them, and are not meant to be called directly.

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
    guard try !ExpectationPolling().wait(timeout: timeout, until: condition) else { return }

    ExpectationReporter.report(
        message: ExpectationFailure.message(
            expression: expression,
            comment: comment(),
            timeout: timeout,
            difference: nil
        ),
        filePath: filePath,
        line: line
    )
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
    var values: (Value, Value)?
    let isTrue = try ExpectationPolling().wait(timeout: timeout) {
        let pair = (try lhs(), try rhs())
        values = pair
        return try isEqual(pair.0, pair.1)
    }
    guard !isTrue, let values else { return }

    ExpectationReporter.report(
        message: ExpectationFailure.message(
            expression: expression,
            comment: comment(),
            timeout: timeout,
            difference: diff(values.0, values.1)
        ),
        filePath: filePath,
        line: line
    )
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
    var values: (LHS, RHS)?
    let isTrue = try ExpectationPolling().wait(timeout: timeout) {
        let pair = (try lhs(), try rhs())
        values = pair
        return try isEqual(pair.0, pair.1)
    }
    guard !isTrue, let values else { return }

    ExpectationReporter.report(
        message: ExpectationFailure.message(
            expression: expression,
            comment: comment(),
            timeout: timeout,
            difference: diff(values.0 as Any, values.1 as Any)
        ),
        filePath: filePath,
        line: line
    )
}
