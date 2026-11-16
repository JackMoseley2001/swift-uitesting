#if canImport(Darwin)
import Foundation
import UITesting
import XCTest

struct AuthState: LaunchPayload, Equatable {
    var isLoggedIn: Bool
}

struct TestError: Error, Equatable {
    var message: String
}

final class EventLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    var events: [String] {
        lock.withLock { storage }
    }

    func record(_ event: String) {
        lock.withLock { storage.append(event) }
    }
}

struct RecordingTrait: UITestTrait {
    var name: String
    var log: EventLog
    var prepareError: TestError?
    var setUpError: TestError?
    var tearDownError: TestError?

    func prepare(_ launch: inout LaunchConfiguration) throws {
        log.record("prepare \(name)")
        if let prepareError { throw prepareError }
    }

    func setUp(_ context: UITestContext) async throws {
        log.record("setUp \(name)")
        if let setUpError { throw setUpError }
    }

    func tearDown(_ context: UITestContext) async throws {
        log.record("tearDown \(name)")
        if let tearDownError { throw tearDownError }
    }
}

struct EmptyTrait: UITestTrait {}
#endif
