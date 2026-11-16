#if canImport(Darwin)
import UITesting

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
#endif
