import Foundation

/// The launch arguments and environment that a UI test passes to the app it launches.
///
/// Build up a configuration, then copy it onto the application before launching:
///
/// ```swift
/// var launch = LaunchConfiguration()
/// launch.arguments.append("--skip-onboarding")
/// try launch.setPayload(AuthState(isLoggedIn: false))
///
/// let app = XCUIApplication()
/// app.launchArguments = launch.arguments
/// app.launchEnvironment = launch.environment
/// app.launch()
/// ```
///
/// The app reads the same values back through ``LaunchTraits``.
public struct LaunchConfiguration: Sendable, Equatable {
    /// The arguments to launch the app with.
    ///
    /// Use arguments for simple flags that the app checks with ``LaunchTraits/hasArgument(_:)``.
    public var arguments: [String]

    /// The environment variables to launch the app with.
    public var environment: [String: String]

    /// Creates a launch configuration.
    ///
    /// - Parameters:
    ///   - arguments: The arguments to launch the app with.
    ///   - environment: The environment variables to launch the app with.
    public init(arguments: [String] = [], environment: [String: String] = [:]) {
        self.arguments = arguments
        self.environment = environment
    }

    /// Adds a payload for the app to read, replacing any payload with the same key.
    ///
    /// The payload is encoded as JSON and stored in ``environment``. The app reads it
    /// with ``LaunchTraits/subscript(_:)`` or ``LaunchTraits/payload(_:)``.
    ///
    /// - Parameter payload: The value to send to the app.
    /// - Throws: An error if the payload cannot be encoded.
    public mutating func setPayload<Payload: LaunchPayload>(_ payload: Payload) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(payload)
        environment[LaunchEnvironmentKey.payload(Payload.launchKey)] = String(decoding: data, as: UTF8.self)
    }

    /// Asks the app to run without animations, which the app sees as ``LaunchTraits/animationsDisabled``.
    public mutating func disableAnimations() {
        environment[LaunchEnvironmentKey.animationsDisabled] = "1"
    }

    /// Launches the app in a time zone, which the app sees as `TimeZone.current`.
    ///
    /// The system reads the time zone of a process from its environment, so the app
    /// needs no code for this.
    ///
    /// - Parameter timeZone: The time zone the app runs in.
    public mutating func setTimeZone(_ timeZone: TimeZone) {
        environment[LaunchEnvironmentKey.timeZone] = timeZone.identifier
    }

    /// Asks the app to treat a date as the current one, which the app sees as ``LaunchTraits/now``.
    ///
    /// - Parameter date: The date the app should use in place of the clock.
    public mutating func setNow(_ date: Date) {
        environment[LaunchEnvironmentKey.now] = "\(date.timeIntervalSince1970)"
    }

    /// Marks the launch as coming from a UI test, which the app sees as ``LaunchTraits/isUITesting``.
    package mutating func markAsUITesting() {
        environment[LaunchEnvironmentKey.isUITesting] = "1"
    }
}
