import Testing

@testable import UITesting

@Suite
struct LaunchTraitTests {
    @Test
    func launchArgumentAppendsAnArgument() throws {
        let launch = try LaunchConfiguration(applying: [
            .launchArgument("--skip-onboarding"),
            .launchArguments(["-AppleLanguages", "(fr)"]),
        ])

        #expect(launch.arguments == ["--skip-onboarding", "-AppleLanguages", "(fr)"])
    }

    @Test
    func environmentSetsAVariable() throws {
        let launch = try LaunchConfiguration(applying: [
            .environment("API_BASE_URL", "http://localhost:8080")
        ])

        #expect(launch.environment["API_BASE_URL"] == "http://localhost:8080")
    }

    @Test
    func laterEnvironmentValueReplacesAnEarlierOne() throws {
        let launch = try LaunchConfiguration(applying: [
            .environment("THEME", "light"),
            .environment("THEME", "dark"),
        ])

        #expect(launch.environment["THEME"] == "dark")
    }

    @Test
    func launchSendsAPayloadTheAppCanRead() throws {
        let launch = try LaunchConfiguration(applying: [
            .launch(AuthState(isLoggedIn: true))
        ])

        let traits = LaunchTraits(arguments: launch.arguments, environment: launch.environment)
        #expect(traits[AuthState.self] == AuthState(isLoggedIn: true))
    }

    @Test
    func laterPayloadReplacesAnEarlierOneOfTheSameType() throws {
        let launch = try LaunchConfiguration(applying: [
            .launch(AuthState(isLoggedIn: false)),
            .launch(AuthState(isLoggedIn: true)),
        ])

        let traits = LaunchTraits(arguments: launch.arguments, environment: launch.environment)
        #expect(traits[AuthState.self] == AuthState(isLoggedIn: true))
    }

    @Test
    func payloadTraitCanBeGivenAShorterName() throws {
        let launch = try LaunchConfiguration(applying: [.loggedOut])

        let traits = LaunchTraits(arguments: launch.arguments, environment: launch.environment)
        #expect(traits[AuthState.self] == AuthState(isLoggedIn: false))
    }
}

extension UITestTrait where Self == LaunchPayloadTrait<AuthState> {
    static var loggedOut: Self { .launch(AuthState(isLoggedIn: false)) }
}
