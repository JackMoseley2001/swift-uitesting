import Foundation

@testable import UITesting

struct AuthState: LaunchPayload, Equatable {
    var isLoggedIn: Bool
}

struct TestError: Error, Equatable {
    var message: String
}

struct EmptyTrait: UITestTrait {}

struct ThrowingTrait: UITestTrait {
    var error: TestError

    func prepare(_ launch: inout LaunchConfiguration) throws {
        throw error
    }
}

/// Runs an operation and returns the expectation failures it reported, in place of
/// reporting them to XCTest.
func reportedFailures(in operation: () throws -> Void) rethrows -> [ExpectationFailure] {
    let recorded = RecordedFailures()
    try ExpectationReporter.$handler.withValue({ recorded.append($0) }) {
        try operation()
    }
    return recorded.failures
}

/// Runs an asynchronous operation and returns the expectation failures it reported.
func reportedFailures(
    isolation: isolated (any Actor)? = #isolation,
    in operation: () async throws -> Void
) async rethrows -> [ExpectationFailure] {
    let recorded = RecordedFailures()
    try await ExpectationReporter.$handler.withValue({ recorded.append($0) }) {
        try await operation()
    }
    return recorded.failures
}

private final class RecordedFailures: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [ExpectationFailure] = []

    var failures: [ExpectationFailure] {
        lock.withLock { storage }
    }

    func append(_ failure: ExpectationFailure) {
        lock.withLock { storage.append(failure) }
    }
}
