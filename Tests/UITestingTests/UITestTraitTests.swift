#if canImport(Darwin)
import XCTest

@testable import UITesting

final class UITestTraitTests: XCTestCase {
    func testLaunchIsMarkedAsUITesting() throws {
        let launch = try LaunchConfiguration(applying: [])

        XCTAssertTrue(LaunchTraits(environment: launch.environment).isUITesting)
        XCTAssertEqual(launch.arguments, [])
    }

    func testTraitWithoutAnImplementationChangesNothing() throws {
        let launch = try LaunchConfiguration(applying: [EmptyTrait()])

        XCTAssertEqual(launch, try LaunchConfiguration(applying: []))
    }

    func testPrepareErrorIsThrown() {
        let trait = RecordingTrait(name: "a", log: EventLog(), prepareError: TestError(message: "prepare"))

        XCTAssertThrowsError(try LaunchConfiguration(applying: [trait])) { error in
            XCTAssertEqual(error as? TestError, TestError(message: "prepare"))
        }
    }
}
#endif
