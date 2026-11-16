import UITesting
import XCTest

@UITestSuite(traits: .example(.launchSettings))
final class LaunchSettingsTests: XCTestCase {
    @UITest
    func defaultsApplyWithoutAnyTraits(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.betaFeatures].label == "off")
        #expect(app[LaunchSettingsID.orientation].label == "portrait")
    }

    @UITest(traits: .language("fr"))
    func languageIsPassedToTheApp(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.preferredLanguage].label.hasPrefix("fr"))
    }

    @UITest(traits: .locale("fr_FR"))
    func localeIsPassedToTheApp(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.region].label == "FR")
    }

    @UITest(traits: .userDefault(DefaultsKey.showsBetaFeatures, true))
    func userDefaultIsOverridden(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.betaFeatures].label == "on")
    }

    @UITest(traits: .orientation(.landscapeLeft))
    func deviceIsRotated(app: XCUIApplication) {
        #expect(app[LaunchSettingsID.orientation].label == "landscape", within: .seconds(5))
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
