import Foundation

/// The launch arguments, environment and payloads that a UI test passed to the app.
///
/// Read ``current`` in the app to find out how a UI test wants it configured:
///
/// ```swift
/// let traits = LaunchTraits.current
///
/// if traits.hasArgument("--skip-onboarding") {
///     onboarding.markAsSeen()
/// }
///
/// if let auth = traits[AuthState.self] {
///     session.override(isLoggedIn: auth.isLoggedIn, userID: auth.userID)
/// }
/// ```
///
/// To exercise the same code paths in unit tests and previews, create an instance with
/// ``init(arguments:environment:)`` and pass it to the code that reads it.
public struct LaunchTraits: Sendable {
    /// The traits the current process was launched with.
    ///
    /// In release builds this is always empty, so that a shipped app cannot be reconfigured
    /// through its arguments or environment. To read launch data in a release build, create
    /// an instance with ``init(processInfo:)`` instead.
    public static let current: LaunchTraits = {
        #if DEBUG
            LaunchTraits(processInfo: .processInfo)
        #else
            LaunchTraits()
        #endif
    }()

    /// The arguments the app was launched with.
    public let arguments: [String]

    /// The environment variables the app was launched with.
    public let environment: [String: String]

    /// Creates traits from explicit arguments and environment variables.
    ///
    /// - Parameters:
    ///   - arguments: The launch arguments.
    ///   - environment: The launch environment variables.
    public init(arguments: [String] = [], environment: [String: String] = [:]) {
        self.arguments = arguments
        self.environment = environment
    }

    /// Creates traits from the arguments and environment of a process.
    ///
    /// Unlike ``current``, this reads the process in every build configuration.
    ///
    /// - Parameter processInfo: The process to read.
    public init(processInfo: ProcessInfo) {
        self.init(arguments: processInfo.arguments, environment: processInfo.environment)
    }

    /// Whether the app was launched by a UI test.
    public var isUITesting: Bool {
        environment[LaunchEnvironmentKey.isUITesting] == "1"
    }

    /// Returns whether the app was launched with the given argument.
    ///
    /// - Parameter argument: The argument to look for, such as `"--skip-onboarding"`.
    public func hasArgument(_ argument: String) -> Bool {
        arguments.contains(argument)
    }

    /// Returns the payload of the given type, if the UI test sent one.
    ///
    /// - Parameter type: The type of payload to read.
    /// - Returns: The decoded payload, or `nil` if the UI test did not send one.
    /// - Throws: ``LaunchPayloadDecodingError`` if a payload is present but cannot be decoded.
    public func payload<Payload: LaunchPayload>(_ type: Payload.Type = Payload.self) throws -> Payload? {
        guard let json = environment[LaunchEnvironmentKey.payload(Payload.launchKey)] else {
            return nil
        }
        do {
            return try JSONDecoder().decode(Payload.self, from: Data(json.utf8))
        } catch {
            throw LaunchPayloadDecodingError(launchKey: Payload.launchKey, underlyingError: error)
        }
    }

    /// The payload of the given type, or `nil` if the UI test did not send one.
    ///
    /// A payload that is present but cannot be decoded stops the app in debug builds,
    /// so that a mismatch between the app and its tests is not mistaken for a missing
    /// payload. In release builds it is `nil`. Use ``payload(_:)`` to handle the error yourself.
    public subscript<Payload: LaunchPayload>(_ type: Payload.Type) -> Payload? {
        do {
            return try payload(type)
        } catch {
            assertionFailure("\(error)")
            return nil
        }
    }
}
