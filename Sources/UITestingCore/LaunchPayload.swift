/// A typed value that a UI test sends to the app it launches.
///
/// Declare payload types in code that is compiled into both the app and its UI test target,
/// such as a shared framework or a file that is a member of both targets.
///
/// ```swift
/// struct AuthState: LaunchPayload {
///     var isLoggedIn: Bool
///     var userID: String?
/// }
/// ```
///
/// A UI test adds the payload to the app's launch with ``LaunchConfiguration/setPayload(_:)``,
/// and the app reads it back from ``LaunchTraits``:
///
/// ```swift
/// if let auth = LaunchTraits.current[AuthState.self] {
///     session.override(isLoggedIn: auth.isLoggedIn, userID: auth.userID)
/// }
/// ```
///
/// Payloads travel in the launch environment as JSON, so keep them small. Send a
/// reference to large data, such as the name of a bundled fixture, rather than the data itself.
public protocol LaunchPayload: Codable, Sendable {
    /// The key that identifies this payload type in the launch environment.
    ///
    /// The default is the unqualified name of the type, which is the same in the app
    /// and in the UI test target even though the two are separate modules.
    ///
    /// Provide your own key when two payload types share a name, or to keep the key
    /// stable when a type is renamed.
    static var launchKey: String { get }
}

extension LaunchPayload {
    public static var launchKey: String {
        String(describing: Self.self)
    }
}
