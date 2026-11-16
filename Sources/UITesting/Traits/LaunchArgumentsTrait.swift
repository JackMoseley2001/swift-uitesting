/// A trait that adds arguments to the launch of the app.
///
/// Create one with ``UITestTrait/launchArgument(_:)`` or ``UITestTrait/launchArguments(_:)``.
public struct LaunchArgumentsTrait: UITestTrait {
    /// The arguments to add.
    public let arguments: [String]

    public func prepare(_ launch: inout LaunchConfiguration) {
        launch.arguments.append(contentsOf: arguments)
    }
}

extension UITestTrait where Self == LaunchArgumentsTrait {
    /// Launches the app with an additional argument.
    ///
    /// The app checks for the argument with `LaunchTraits.current.hasArgument(_:)`.
    ///
    /// - Parameter argument: The argument to add, such as `"--skip-onboarding"`.
    public static func launchArgument(_ argument: String) -> Self {
        LaunchArgumentsTrait(arguments: [argument])
    }

    /// Launches the app with additional arguments.
    ///
    /// - Parameter arguments: The arguments to add, in order.
    public static func launchArguments(_ arguments: [String]) -> Self {
        LaunchArgumentsTrait(arguments: arguments)
    }

    /// Launches the app in a language.
    ///
    /// This sets the app's preferred language for the launch, in the same way as choosing
    /// an app language in a scheme. The app shows that language if it is localised for it.
    ///
    /// - Parameter identifier: A language identifier, such as `"fr"` or `"pt-BR"`.
    public static func language(_ identifier: String) -> Self {
        LaunchArgumentsTrait(arguments: ["-AppleLanguages", "(\(identifier))"])
    }

    /// Launches the app in a locale, which sets its region and formatting conventions.
    ///
    /// - Parameter identifier: A locale identifier, such as `"fr_FR"`.
    public static func locale(_ identifier: String) -> Self {
        LaunchArgumentsTrait(arguments: ["-AppleLocale", identifier])
    }

    /// Overrides a value in the app's `UserDefaults` for the launch.
    ///
    /// The app reads the value from `UserDefaults.standard` as usual, with no extra code.
    /// The override lasts for that launch only and is not saved.
    ///
    /// ```swift
    /// @UITest(traits: .userDefault("hasSeenOnboarding", true))
    /// func opensTheHomeScreen(app: XCUIApplication) { /* ... */ }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The key of the value in `UserDefaults`.
    ///   - value: The value the app should read.
    public static func userDefault(_ key: String, _ value: Bool) -> Self {
        LaunchArgumentsTrait(arguments: ["-\(key)", value ? "YES" : "NO"])
    }

    /// Overrides a value in the app's `UserDefaults` for the launch.
    ///
    /// - Parameters:
    ///   - key: The key of the value in `UserDefaults`.
    ///   - value: The value the app should read.
    public static func userDefault(_ key: String, _ value: Int) -> Self {
        LaunchArgumentsTrait(arguments: ["-\(key)", "\(value)"])
    }

    /// Overrides a value in the app's `UserDefaults` for the launch.
    ///
    /// - Parameters:
    ///   - key: The key of the value in `UserDefaults`.
    ///   - value: The value the app should read.
    public static func userDefault(_ key: String, _ value: Double) -> Self {
        LaunchArgumentsTrait(arguments: ["-\(key)", "\(value)"])
    }

    /// Overrides a value in the app's `UserDefaults` for the launch.
    ///
    /// - Parameters:
    ///   - key: The key of the value in `UserDefaults`.
    ///   - value: The value the app should read.
    public static func userDefault(_ key: String, _ value: String) -> Self {
        LaunchArgumentsTrait(arguments: ["-\(key)", value])
    }
}
