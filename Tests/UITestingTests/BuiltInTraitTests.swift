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
    func userDefaultPassesEachTypeOfValue() throws {
        let launch = try LaunchConfiguration(applying: [
            .userDefault("hasSeenOnboarding", true),
            .userDefault("isPremium", false),
            .userDefault("launchCount", 3),
            .userDefault("textScale", 1.5),
            .userDefault("theme", "dark"),
        ])

        #Testing::expect(
            launch.arguments == [
                "-hasSeenOnboarding", "YES",
                "-isPremium", "NO",
                "-launchCount", "3",
                "-textScale", "1.5",
                "-theme", "dark",
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
}
