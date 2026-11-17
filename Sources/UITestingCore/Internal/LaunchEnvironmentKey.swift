/// The names of the launch environment variables that carry UITesting data.
package enum LaunchEnvironmentKey {
    /// The variable that is set to `"1"` when the app is launched by a UI test.
    package static let isUITesting = "UITESTING_ACTIVE"

    /// The variable that is set to `"1"` when the UI test asks the app to run without animations.
    package static let animationsDisabled = "UITESTING_ANIMATIONS_DISABLED"

    /// The variable that holds the port on which the UI test waits for the app to connect.
    package static let messagePort = "UITESTING_MESSAGE_PORT"

    /// The name of the variable that carries the payload with the given key.
    package static func payload(_ launchKey: String) -> String {
        "UITESTING_PAYLOAD_" + launchKey
    }
}
