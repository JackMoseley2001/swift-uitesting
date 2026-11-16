import Testing
import XCTest

@testable import UITesting

@UITestSuite(.launchArgument("--suite"), .environment("SCOPE", "suite"))
final class SuiteWithTraits: XCTestCase {}

@UITestSuite
final class SuiteWithoutTraits: XCTestCase {}

@MainActor
@UITestSuite(.launchArgument("--main-actor"))
final class MainActorSuite: XCTestCase {}

@Suite
struct UITestSuiteMacroTests {
    /// Reads the traits through the protocol, which only compiles if the macro added the conformance.
    private func traits<Suite: UITestSuite>(of suite: Suite.Type) -> [any UITestTrait] {
        Suite.suiteTraits
    }

    @Test
    func traitsComeFromTheMacroArguments() throws {
        let launch = try LaunchConfiguration(applying: traits(of: SuiteWithTraits.self))

        #expect(launch.arguments == ["--suite"])
        #expect(launch.environment["SCOPE"] == "suite")
    }

    @Test
    func suiteWithoutArgumentsHasNoTraits() {
        #expect(traits(of: SuiteWithoutTraits.self).isEmpty)
    }

    @Test
    func traitsOfAMainActorSuiteCanBeReadFromAnyContext() throws {
        let launch = try LaunchConfiguration(applying: traits(of: MainActorSuite.self))

        #expect(launch.arguments == ["--main-actor"])
    }
}
