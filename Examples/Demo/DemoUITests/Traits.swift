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
