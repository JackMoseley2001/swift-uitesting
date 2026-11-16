import Testing
import UITestingCore

@Suite
struct LaunchPayloadTests {
    @Test
    func defaultKeyIsTheTypeName() {
        #expect(AuthState.launchKey == "AuthState")
    }

    @Test
    func defaultKeyOfANestedTypeOmitsItsParent() {
        #expect(Settings.Theme.launchKey == "Theme")
    }

    @Test
    func keyCanBeCustomised() {
        #expect(FeatureFlags.launchKey == "flags")
    }
}
