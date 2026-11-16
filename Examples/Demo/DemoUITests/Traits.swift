import UITesting

extension UITestTrait where Self == LaunchPayloadTrait<AuthState> {
    /// Launches the app signed out.
    static var loggedOut: Self {
        .launch(AuthState(isLoggedIn: false))
    }

    /// Launches the app signed in as the given user.
    static func loggedIn(as name: String) -> Self {
        .launch(AuthState(isLoggedIn: true, name: name))
    }
}

extension UITestTrait where Self == LaunchArgumentsTrait {
    /// Launches the app with the promo banner showing.
    static var promoBanner: Self {
        .launchArgument(LaunchArgument.showPromoBanner)
    }
}

extension UITestTrait where Self == LaunchPayloadTrait<Example> {
    /// Launches the app on the screen of the given example, instead of the list of examples.
    static func example(_ example: Example) -> Self {
        .launch(example)
    }
}

extension UITestTrait where Self == LaunchPayloadTrait<KeyboardDismissal> {
    /// Sets how the profile form's scroll view dismisses the keyboard when it is dragged.
    static func keyboardDismissal(_ dismissal: KeyboardDismissal) -> Self {
        .launch(dismissal)
    }
}
