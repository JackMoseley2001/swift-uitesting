import XCTest

@testable import UITesting

final class LaunchTraitTests: XCTestCase {
    func testLaunchArgumentAppendsAnArgument() throws {
        let launch = try LaunchConfiguration(applying: [
            .launchArgument("--skip-onboarding"),
            .launchArguments(["-AppleLanguages", "(fr)"]),
        ])

        XCTAssertEqual(launch.arguments, ["--skip-onboarding", "-AppleLanguages", "(fr)"])
    }

    func testEnvironmentSetsAVariable() throws {
        let launch = try LaunchConfiguration(applying: [
            .environment("API_BASE_URL", "http://localhost:8080")
        ])

        XCTAssertEqual(launch.environment["API_BASE_URL"], "http://localhost:8080")
    }

    func testLaterEnvironmentValueReplacesAnEarlierOne() throws {
        let launch = try LaunchConfiguration(applying: [
            .environment("THEME", "light"),
            .environment("THEME", "dark"),
        ])

        XCTAssertEqual(launch.environment["THEME"], "dark")
    }

    func testLaunchSendsAPayloadTheAppCanRead() throws {
        let launch = try LaunchConfiguration(applying: [
            .launch(AuthState(isLoggedIn: true))
        ])

        let traits = LaunchTraits(arguments: launch.arguments, environment: launch.environment)
        XCTAssertEqual(traits[AuthState.self], AuthState(isLoggedIn: true))
    }

    func testLaterPayloadReplacesAnEarlierOneOfTheSameType() throws {
        let launch = try LaunchConfiguration(applying: [
            .launch(AuthState(isLoggedIn: false)),
            .launch(AuthState(isLoggedIn: true)),
        ])

        let traits = LaunchTraits(arguments: launch.arguments, environment: launch.environment)
        XCTAssertEqual(traits[AuthState.self], AuthState(isLoggedIn: true))
    }

    func testPayloadTraitCanBeGivenAShorterName() throws {
        let launch = try LaunchConfiguration(applying: [.loggedOut])

        let traits = LaunchTraits(arguments: launch.arguments, environment: launch.environment)
        XCTAssertEqual(traits[AuthState.self], AuthState(isLoggedIn: false))
    }
}

extension UITestTrait where Self == LaunchPayloadTrait<AuthState> {
    static var loggedOut: Self { .launch(AuthState(isLoggedIn: false)) }
}
