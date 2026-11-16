import Testing

@testable import UITesting

@Suite
struct UITestTraitTests {
    @Test
    func launchIsMarkedAsUITesting() throws {
        let launch = try LaunchConfiguration(applying: [])

        #Testing::expect(LaunchTraits(environment: launch.environment).isUITesting)
        #Testing::expect(launch.arguments.isEmpty)
    }

    @Test
    func traitWithoutAnImplementationChangesNothing() throws {
        let launch = try LaunchConfiguration(applying: [EmptyTrait()])
        let launchWithoutTraits = try LaunchConfiguration(applying: [])

        #Testing::expect(launch == launchWithoutTraits)
    }

    @Test
    func prepareErrorIsThrown() {
        let trait = ThrowingTrait(error: TestError(message: "prepare"))

        #Testing::expect(throws: TestError(message: "prepare")) {
            try LaunchConfiguration(applying: [EmptyTrait(), trait])
        }
    }
}
