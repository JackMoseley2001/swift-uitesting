import SwiftUI
import Testing
import XCTest

@testable import UITesting

@Suite
struct BuiltInTraitTests {
    @Test
    func languageSetsTheAppsPreferredLanguage() throws {
        let launch = try LaunchConfiguration(applying: [.language("fr")])

        #Testing::expect(launch.arguments == ["-AppleLanguages", "(fr)"])
    }

    @Test
    func localeSetsTheAppsLocale() throws {
        let launch = try LaunchConfiguration(applying: [.locale("fr_FR")])

        #Testing::expect(launch.arguments == ["-AppleLocale", "fr_FR"])
    }

    @Test
    func dynamicTypeSizeSetsTheAppsPreferredContentSizeCategory() throws {
        let launch = try LaunchConfiguration(applying: [.dynamicTypeSize(.accessibility3)])

        #Testing::expect(
            launch.arguments == ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        )
    }

    @Test
    func everyDynamicTypeSizeHasTheNameOfItsContentSizeCategory() {
        #Testing::expect(
            DynamicTypeSize.allCases.map(\.contentSizeCategoryName) == [
                "UICTContentSizeCategoryXS",
                "UICTContentSizeCategoryS",
                "UICTContentSizeCategoryM",
                "UICTContentSizeCategoryL",
                "UICTContentSizeCategoryXL",
                "UICTContentSizeCategoryXXL",
                "UICTContentSizeCategoryXXXL",
                "UICTContentSizeCategoryAccessibilityM",
                "UICTContentSizeCategoryAccessibilityL",
                "UICTContentSizeCategoryAccessibilityXL",
                "UICTContentSizeCategoryAccessibilityXXL",
                "UICTContentSizeCategoryAccessibilityXXXL"
            ]
        )
    }

    @Test
    func userDefaultPassesEachTypeOfValue() throws {
        let launch = try LaunchConfiguration(applying: [
            .userDefault("hasSeenOnboarding", true),
            .userDefault("isPremium", false),
            .userDefault("launchCount", 3),
            .userDefault("textScale", 1.5),
            .userDefault("theme", "dark")
        ])

        #Testing::expect(
            launch.arguments == [
                "-hasSeenOnboarding", "YES",
                "-isPremium", "NO",
                "-launchCount", "3",
                "-textScale", "1.5",
                "-theme", "dark"
            ]
        )
    }

    @Test
    func enabledTraitWithATrueConditionLetsTheTestRun() throws {
        let launch = try LaunchConfiguration(applying: [.enabled(if: true), .launchArgument("--flag")])

        #Testing::expect(launch.arguments == ["--flag"])
    }

    @Test
    func enabledTraitWithAFalseConditionSkipsTheTest() {
        #Testing::expect(throws: XCTSkip.self) {
            try LaunchConfiguration(applying: [.enabled(if: false, "Needs a device")])
        }
    }

    @Test
    func disabledTraitSkipsTheTest() {
        #Testing::expect(throws: XCTSkip.self) {
            try LaunchConfiguration(applying: [.disabled("Not ready")])
        }
    }

    @Test
    func disabledTraitWithAConditionSkipsOnlyWhenItIsTrue() throws {
        _ = try LaunchConfiguration(applying: [.disabled(if: false)])

        #Testing::expect(throws: XCTSkip.self) {
            try LaunchConfiguration(applying: [.disabled(if: true)])
        }
    }

    @Test
    func conditionIsEvaluatedWhenTheTestStarts() throws {
        let trait: UITesting.ConditionTrait = .enabled(if: try Self.failingCondition())

        #Testing::expect(throws: TestError(message: "condition")) {
            try LaunchConfiguration(applying: [trait])
        }
    }

    @Test
    func skippedTestKeepsItsComment() {
        let trait: UITesting.ConditionTrait = .disabled("Not ready")

        #Testing::expect(trait.comment == "Not ready")
    }

    private static func failingCondition() throws -> Bool {
        throw TestError(message: "condition")
    }

    @Test
    func theAppIsLaunchedAutomaticallyByDefault() {
        #Testing::expect(UITestRunner.launchesAutomatically(with: []))
        #Testing::expect(UITestRunner.launchesAutomatically(with: [.launchArgument("--flag"), EmptyTrait()]))
    }

    @Test
    func manualLaunchLeavesLaunchingToTheTest() {
        #Testing::expect(!UITestRunner.launchesAutomatically(with: [.manualLaunch]))
        #Testing::expect(!UITestRunner.launchesAutomatically(with: [.launchArgument("--flag"), .manualLaunch]))
    }

    @Test
    func manualLaunchDoesNotChangeTheLaunchConfiguration() throws {
        let launch = try LaunchConfiguration(applying: [.manualLaunch, .launchArgument("--flag")])

        #Testing::expect(launch == (try LaunchConfiguration(applying: [.launchArgument("--flag")])))
    }

    @Test
    func resetAuthorizationKeepsItsResourcesInOrder() {
        let trait: ResetAuthorizationTrait = .resetAuthorization(for: .photos, .camera)

        #Testing::expect(trait.resources == [.photos, .camera])
    }

    @Test
    func resetAuthorizationDoesNotChangeTheLaunchConfiguration() throws {
        let launch = try LaunchConfiguration(applying: [.resetAuthorization(for: .photos)])

        #Testing::expect(launch == (try LaunchConfiguration(applying: [])))
    }

    @Test
    func timeZoneIsPassedWhereTheSystemReadsIt() throws {
        let launch = try LaunchConfiguration(applying: [.timeZone("Asia/Tokyo")])

        #Testing::expect(launch.environment["TZ"] == "Asia/Tokyo")
    }

    @Test
    func laterTimeZoneReplacesAnEarlierOne() throws {
        let launch = try LaunchConfiguration(applying: [.timeZone("Asia/Tokyo"), .timeZone("Europe/London")])

        #Testing::expect(launch.environment["TZ"] == "Europe/London")
    }

    @Test
    func timeZoneThatDoesNotExistFailsTheLaunch() {
        #Testing::expect(
            throws: LaunchSettingError(message: "There is no time zone with the identifier \"Mars/Olympus\"")
        ) {
            try LaunchConfiguration(applying: [.timeZone("Mars/Olympus")])
        }
    }

    @Test
    func nowIsReadBackByTheApp() throws {
        let date = Date(timeIntervalSince1970: 1_773_480_600)
        let launch = try LaunchConfiguration(applying: [.now(date)])

        #Testing::expect(LaunchTraits(environment: launch.environment).now == date)
    }

    @Test
    func nowCanBeWrittenInISO8601() throws {
        let utc = try LaunchConfiguration(applying: [.now("2026-03-14T09:30:00Z")])
        let offset = try LaunchConfiguration(applying: [.now("2026-03-14T18:30:00+09:00")])
        let fraction = try LaunchConfiguration(applying: [.now("2026-03-14T09:30:00.500Z")])

        let date = Date(timeIntervalSince1970: 1_773_480_600)
        #Testing::expect(LaunchTraits(environment: utc.environment).now == date)
        #Testing::expect(LaunchTraits(environment: offset.environment).now == date)
        #Testing::expect(LaunchTraits(environment: fraction.environment).now == date.addingTimeInterval(0.5))
    }

    @Test
    func nowThatIsNotADateFailsTheLaunch() {
        #Testing::expect(throws: LaunchSettingError.self) {
            try LaunchConfiguration(applying: [.now("14 March 2026")])
        }
        #Testing::expect(throws: LaunchSettingError.self) {
            // No time zone, so it is not one moment.
            try LaunchConfiguration(applying: [.now("2026-03-14T09:30:00")])
        }
    }

    @Test
    func locationDoesNotChangeTheLaunchConfiguration() throws {
        guard #available(macOS 13.3, iOS 16.4, tvOS 16.4, watchOS 9.4, *) else { return }
        let launch = try LaunchConfiguration(applying: [.location(latitude: 51.5074, longitude: -0.1278)])

        #Testing::expect(launch == (try LaunchConfiguration(applying: [])))
    }

    @Test
    func locationThatIsNotOnTheEarthFailsTheLaunch() {
        guard #available(macOS 13.3, iOS 16.4, tvOS 16.4, watchOS 9.4, *) else { return }
        #Testing::expect(throws: LaunchSettingError.self) {
            try LaunchConfiguration(applying: [.location(latitude: 91, longitude: 0)])
        }
        #Testing::expect(throws: LaunchSettingError.self) {
            try LaunchConfiguration(applying: [.location(latitude: 0, longitude: -180.5)])
        }
    }
}
