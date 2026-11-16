#if canImport(SwiftUI)
import SwiftUI
import Testing
import UITestingCore

@Suite
struct LaunchTraitsEnvironmentTests {
    @Test
    func defaultsToTheCurrentLaunchTraits() {
        let values = EnvironmentValues()

        #expect(values.launchTraits.arguments == LaunchTraits.current.arguments)
        #expect(values.launchTraits.environment == LaunchTraits.current.environment)
    }

    @Test
    func canBeOverridden() {
        var values = EnvironmentValues()

        values.launchTraits = LaunchTraits(arguments: ["--show-promo-banner"])

        #expect(values.launchTraits.hasArgument("--show-promo-banner"))
        #expect(values.launchTraits.environment.isEmpty)
    }
}
#endif
