import Foundation
import Testing
import UITestingCore

@Suite
struct LaunchTraitsTests {
    @Test
    func animationsAreNotDisabledUnlessTheTestAsks() {
        #expect(!LaunchTraits().animationsDisabled)
        #expect(!LaunchTraits(environment: ["UITESTING_ACTIVE": "1"]).animationsDisabled)
        #expect(!LaunchTraits(environment: ["UITESTING_ANIMATIONS_DISABLED": "0"]).animationsDisabled)
        #expect(LaunchTraits(environment: ["UITESTING_ANIMATIONS_DISABLED": "1"]).animationsDisabled)
    }

    @Test
    func isUITestingIsFalseWithoutTheMarker() {
        #expect(!LaunchTraits().isUITesting)
        #expect(!LaunchTraits(environment: ["UITESTING_ACTIVE": "0"]).isUITesting)
    }

    @Test
    func isUITestingIsTrueForAMarkedLaunch() {
        var launch = LaunchConfiguration()
        launch.markAsUITesting()

        #expect(LaunchTraits(environment: launch.environment).isUITesting)
    }

    @Test
    func hasArgumentMatchesWholeArguments() {
        let traits = LaunchTraits(arguments: ["/path/to/App", "--skip-onboarding"])

        #expect(traits.hasArgument("--skip-onboarding"))
        #expect(!traits.hasArgument("--skip"))
    }

    @Test
    func payloadIsNilWhenNoneWasSent() throws {
        let traits = LaunchTraits()

        #expect(try traits.payload(AuthState.self) == nil)
        #expect(traits[AuthState.self] == nil)
    }

    @Test
    func payloadsRoundTripThroughALaunchConfiguration() throws {
        var launch = LaunchConfiguration()
        try launch.setPayload(AuthState(isLoggedIn: true, userID: "user-42"))
        try launch.setPayload(FeatureFlags(enabled: ["search"]))

        let traits = LaunchTraits(arguments: launch.arguments, environment: launch.environment)

        #expect(traits[AuthState.self] == AuthState(isLoggedIn: true, userID: "user-42"))
        #expect(traits[FeatureFlags.self] == FeatureFlags(enabled: ["search"]))
        #expect(traits[Settings.Theme.self] == nil)
    }

    @Test
    func payloadThrowsWhenItCannotBeDecoded() {
        let traits = LaunchTraits(environment: ["UITESTING_PAYLOAD_AuthState": #"{"isLoggedIn":"yes"}"#])

        do {
            _ = try traits.payload(AuthState.self)
            Issue.record("Expected a LaunchPayloadDecodingError to be thrown")
        } catch let error as LaunchPayloadDecodingError {
            #expect(error.launchKey == "AuthState")
            #expect(error.description.hasPrefix(#"The launch payload "AuthState" could not be decoded: "#))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func initFromProcessInfoReadsTheProcess() {
        let traits = LaunchTraits(processInfo: .processInfo)

        #expect(traits.arguments == ProcessInfo.processInfo.arguments)
        #expect(traits.environment == ProcessInfo.processInfo.environment)
    }

    #if DEBUG
        @Test
        func currentReadsTheProcessInDebugBuilds() {
            #expect(LaunchTraits.current.arguments == ProcessInfo.processInfo.arguments)
            #expect(LaunchTraits.current.environment == ProcessInfo.processInfo.environment)
        }
    #endif

    @Test
    func nowIsTheDateTheTestFixed() {
        var launch = LaunchConfiguration()
        let date = Date(timeIntervalSince1970: 1_773_480_600.25)
        launch.setNow(date)

        let traits = LaunchTraits(environment: launch.environment)

        #expect(traits.fixedNow == date)
        #expect(traits.now == date)
    }

    @Test
    func nowIsTheClockWhenNoDateWasFixed() {
        let before = Date()
        let traits = LaunchTraits()

        #expect(traits.fixedNow == nil)
        #expect(traits.now >= before)
        #expect(traits.now <= Date())
    }

    @Test
    func fixedNowThatIsNotANumberIsIgnored() {
        #expect(LaunchTraits(environment: ["UITESTING_NOW": "tomorrow"]).fixedNow == nil)
    }
}
