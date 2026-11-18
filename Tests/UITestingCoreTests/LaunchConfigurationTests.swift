import Foundation
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

    @Test
    func disableAnimationsSetsTheRequest() {
        var launch = LaunchConfiguration()

        launch.disableAnimations()

        #expect(launch.environment == ["UITESTING_ANIMATIONS_DISABLED": "1"])
        #expect(LaunchTraits(environment: launch.environment).animationsDisabled)
    }

    @Test
    func setTimeZoneStoresTheIdentifierWhereTheSystemReadsIt() throws {
        var launch = LaunchConfiguration()

        launch.setTimeZone(try #require(TimeZone(identifier: "Asia/Tokyo")))

        #expect(launch.environment == ["TZ": "Asia/Tokyo"])
    }

    @Test
    func setNowStoresTheSecondsSince1970() {
        var launch = LaunchConfiguration()

        launch.setNow(Date(timeIntervalSince1970: 1_773_480_600.25))

        #expect(launch.environment == ["UITESTING_NOW": "1773480600.25"])
    }
}
