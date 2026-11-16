import Testing
import UITestingCore

@Suite
struct LaunchConfigurationTests {
    @Test
    func startsEmpty() {
        let launch = LaunchConfiguration()

        #expect(launch.arguments.isEmpty)
        #expect(launch.environment.isEmpty)
    }

    @Test
    func setPayloadStoresJSONUnderThePayloadKey() throws {
        var launch = LaunchConfiguration()

        try launch.setPayload(AuthState(isLoggedIn: true, userID: "user-42"))

        #expect(launch.environment == [
            "UITESTING_PAYLOAD_AuthState": #"{"isLoggedIn":true,"userID":"user-42"}"#
        ])
    }

    @Test
    func setPayloadUsesACustomKey() throws {
        var launch = LaunchConfiguration()

        try launch.setPayload(FeatureFlags(enabled: ["search"]))

        #expect(launch.environment == ["UITESTING_PAYLOAD_flags": #"{"enabled":["search"]}"#])
    }

    @Test
    func setPayloadReplacesAPayloadWithTheSameKey() throws {
        var launch = LaunchConfiguration()

        try launch.setPayload(AuthState(isLoggedIn: false))
        try launch.setPayload(AuthState(isLoggedIn: true))

        #expect(launch.environment == ["UITESTING_PAYLOAD_AuthState": #"{"isLoggedIn":true}"#])
    }

    @Test
    func setPayloadKeepsOtherValues() throws {
        var launch = LaunchConfiguration(
            arguments: ["--skip-onboarding"],
            environment: ["API_BASE_URL": "http://localhost:8080"]
        )

        try launch.setPayload(AuthState(isLoggedIn: false))

        #expect(launch.arguments == ["--skip-onboarding"])
        #expect(launch.environment["API_BASE_URL"] == "http://localhost:8080")
        #expect(launch.environment.count == 2)
    }

    @Test
    func markAsUITestingSetsTheMarker() {
        var launch = LaunchConfiguration()

        launch.markAsUITesting()

        #expect(launch.environment == ["UITESTING_ACTIVE": "1"])
    }
}
