/// A trait that sets an environment variable for the launch of the app.
///
/// Create one with ``UITestTrait/environment(_:_:)``.
public struct LaunchEnvironmentTrait: UITestTrait {
    /// The name of the environment variable.
    public let name: String

    /// The value of the environment variable.
    public let value: String

    public func prepare(_ launch: inout LaunchConfiguration) {
        launch.environment[name] = value
    }
}

extension UITestTrait where Self == LaunchEnvironmentTrait {
    /// Launches the app with an environment variable, replacing any earlier value for the same name.
    ///
    /// - Parameters:
    ///   - name: The name of the environment variable.
    ///   - value: The value of the environment variable.
    public static func environment(_ name: String, _ value: String) -> Self {
        LaunchEnvironmentTrait(name: name, value: value)
    }
}
