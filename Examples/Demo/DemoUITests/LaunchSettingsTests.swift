import UITesting
import XCTest

@UITestSuite(traits: .example(.launchSettings), .animationsDisabled)
final class LaunchSettingsTests: XCTestCase {
    @UITest
    func defaultsApplyWithoutAnyTraits(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.betaFeatures].label == "off")
        #expect(app[LaunchSettingsID.orientation].label == "portrait")
        // The text size that a watch starts with depends on the size of the watch.
        #if !os(watchOS)
        #expect(app[LaunchSettingsID.textSize].label == "large")
        #endif
    }

    @UITest(traits: .language("fr"))
    func languageIsPassedToTheApp(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.preferredLanguage].label.hasPrefix("fr"))
    }

    @UITest(traits: .manualLaunch, arguments: ["fr", "de", "ja"])
    func eachLanguageIsPassedToTheApp(_ language: String, context: UITestContext) throws {
        // The traits are the same for every argument, so the test launches the app itself
        // to give each launch its own.
        try context.relaunch(with: .language(language))

        #expect(context.app[LaunchSettingsID.preferredLanguage].label.hasPrefix(language))
    }

    @UITest(traits: .locale("fr_FR"))
    func localeIsPassedToTheApp(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.region].label == "FR")
    }

    @UITest(traits: .userDefault(DefaultsKey.showsBetaFeatures, true))
    func userDefaultIsOverridden(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.betaFeatures].label == "on")
    }

    // Only a device with iOS can be rotated.
    #if os(iOS)
    @UITest(traits: .orientation(.landscapeLeft))
    func deviceIsRotated(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.orientation].label == "landscape", within: .seconds(5))
    }
    #endif

    // A Mac app has no Dynamic Type.
    #if !os(macOS)
    @UITest(traits: .dynamicTypeSize(.accessibility3))
    func dynamicTypeSizeIsPassedToTheApp(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.textSize].label == "accessibility3")
    }
    #endif

    @UITest(traits: .timeZone("Asia/Tokyo"))
    func timeZoneIsPassedToTheApp(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.timeZone].label == "Asia/Tokyo")
    }

    @UITest
    func clockIsUsedWhenNoDateIsFixed(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.now].label == "the clock")
    }

    @UITest(traits: .now("2026-03-14T20:30:00Z"), .timeZone("America/Los_Angeles"))
    func fixedDateIsReadByTheApp(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.now].label == "2026-03-14T20:30:00Z")
        #expect(app[LaunchSettingsID.today].label == "2026-03-14")
    }

    @UITest(traits: .now("2026-03-14T20:30:00Z"), .timeZone("Asia/Tokyo"))
    func fixedDateIsADifferentDayInAnotherTimeZone(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.today].label == "2026-03-15")
    }

    @UITest(traits: .disabled("Shows that a disabled test is skipped"))
    func disabledTestIsSkipped(app: XCUIApplication) {
        XCTFail("A disabled test should not run")
    }

    @UITest(traits: .enabled(if: ProcessInfo.processInfo.environment["UITESTING_DEMO_NEVER_SET"] != nil))
    func conditionThatIsFalseSkipsTheTest(app: XCUIApplication) {
        XCTFail("A test whose condition is false should not run")
    }
}
