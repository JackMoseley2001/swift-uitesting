import UITesting

/// Launches the app past its onboarding screens.
struct SkipOnboarding: UITestTrait {
    func prepare(_ launch: inout LaunchConfiguration) {
        launch.arguments.append("--skip-onboarding")
    }
}

extension UITestTrait where Self == SkipOnboarding {
    /// Launches the app past its onboarding screens.
    static var skipOnboarding: Self { SkipOnboarding() }
}
