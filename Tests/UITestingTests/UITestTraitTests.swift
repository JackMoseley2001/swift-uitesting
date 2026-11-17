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
    func animationsDisabledTraitAsksTheAppToRunWithoutAnimations() throws {
        let launch = try LaunchConfiguration(applying: [.animationsDisabled])
        let launchWithoutTraits = try LaunchConfiguration(applying: [])

        #Testing::expect(LaunchTraits(environment: launch.environment).animationsDisabled)
        #Testing::expect(!LaunchTraits(environment: launchWithoutTraits.environment).animationsDisabled)
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

    @Test
    func applyingTraitsAddsToAnExistingConfiguration() throws {
        let launch = try LaunchConfiguration(applying: [.launchArgument("--first")])

        let relaunch = try launch.applying([.launchArgument("--second"), .environment("NAME", "value")])

        #Testing::expect(relaunch.arguments == ["--first", "--second"])
        #Testing::expect(relaunch.environment["NAME"] == "value")
        #Testing::expect(LaunchTraits(environment: relaunch.environment).isUITesting)
    }

    @Test
    func applyingTraitsLeavesTheOriginalConfigurationUnchanged() throws {
        let launch = try LaunchConfiguration(applying: [.launchArgument("--first")])

        _ = try launch.applying([.launchArgument("--second")])

        #Testing::expect(launch.arguments == ["--first"])
    }

    @Test
    func applyingAPayloadReplacesTheOneAlreadySet() throws {
        let launch = try LaunchConfiguration(applying: [.launch(AuthState(isLoggedIn: true))])

        let relaunch = try launch.applying([.launch(AuthState(isLoggedIn: false))])

        #Testing::expect(LaunchTraits(environment: launch.environment)[AuthState.self] == AuthState(isLoggedIn: true))
        #Testing::expect(LaunchTraits(environment: relaunch.environment)[AuthState.self] == AuthState(isLoggedIn: false))
    }

    @Test
    func applyingNoTraitsKeepsTheConfiguration() throws {
        let launch = try LaunchConfiguration(applying: [.launchArgument("--first")])

        #Testing::expect(try launch.applying([]) == launch)
    }

    @Test
    func applyingATraitThatThrowsPassesTheErrorOn() throws {
        let launch = try LaunchConfiguration(applying: [])

        #Testing::expect(throws: TestError(message: "prepare")) {
            try launch.applying([ThrowingTrait(error: TestError(message: "prepare"))])
        }
    }
}

/// Checks, when the tests are compiled, that `relaunch(with:)` takes traits written the
/// way they are in the macros. It is never called, because a context needs a running UI test.
@MainActor
private func relaunchTakesTraitsWithLeadingDotSyntax(context: UITestContext) throws {
    try context.relaunch()
    try context.relaunch(with: .launchArgument("--flag"), .launch(AuthState(isLoggedIn: false)))
}
