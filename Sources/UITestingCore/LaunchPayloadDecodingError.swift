/// An error thrown when a launch payload is present but cannot be decoded.
///
/// This usually means the app and its UI tests were built from different versions of
/// the payload type.
public struct LaunchPayloadDecodingError: Error, CustomStringConvertible {
    /// The key of the payload that failed to decode.
    public let launchKey: String

    /// The error reported by the decoder.
    public let underlyingError: any Error

    public var description: String {
        "The launch payload \"\(launchKey)\" could not be decoded: \(underlyingError)"
    }
}
