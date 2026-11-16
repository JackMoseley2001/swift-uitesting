/// A trait that sends a payload to the app when it launches.
///
/// Create one with ``UITestTrait/launch(_:)``. To give a payload a shorter name at
/// the point of use, extend `UITestTrait` for this type:
///
/// ```swift
/// extension UITestTrait where Self == LaunchPayloadTrait<AuthState> {
///     static var loggedOut: Self { .launch(AuthState(isLoggedIn: false)) }
/// }
/// ```
public struct LaunchPayloadTrait<Payload: LaunchPayload>: UITestTrait {
    /// The payload to send.
    public let payload: Payload

    public func prepare(_ launch: inout LaunchConfiguration) throws {
        try launch.setPayload(payload)
    }
}

extension UITestTrait {
    /// Launches the app with a payload, replacing any earlier payload of the same type.
    ///
    /// The app reads the payload with `LaunchTraits.current[Payload.self]`.
    ///
    /// - Parameter payload: The value to send to the app.
    public static func launch<Payload: LaunchPayload>(
        _ payload: Payload
    ) -> Self where Self == LaunchPayloadTrait<Payload> {
        LaunchPayloadTrait(payload: payload)
    }
}
