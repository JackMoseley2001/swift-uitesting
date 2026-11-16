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
}
