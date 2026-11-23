/// A typed value that a UI test sends to the app while the app is running.
///
/// A ``LaunchPayload`` configures the app once, when it is launched. A message reaches
/// it later, in the middle of a test, to make something happen that a test cannot do
/// through the user interface: a session that expires, a notification that arrives, a
/// clock that moves on.
///
/// Declare message types in code that is compiled into both the app and its UI test
/// target, as you do for payloads:
///
/// ```swift
/// struct ExpireSession: UITestMessage {}
///
/// struct RenameUser: UITestMessage {
///     var name: String
/// }
/// ```
///
/// A UI test that has the `messageChannel` trait sends a message with
/// `context.send(_:)`. The app receives it with `onUITestMessage(_:perform:)` in
/// SwiftUI, or with ``UITestMessages`` anywhere else.
///
/// Messages travel as JSON, so keep them small.
public protocol UITestMessage: Codable, Sendable {
    /// The name that identifies this type of message between the test and the app.
    ///
    /// The default is the unqualified name of the type, which is the same in the app
    /// and in the UI test target even though the two are separate modules.
    ///
    /// Provide your own name when two message types share a name, or to keep the name
    /// stable when a type is renamed.
    static var messageName: String { get }
}

extension UITestMessage {
    /// The name of the type, unless the type provides a name of its own.
    public static var messageName: String {
        String(describing: Self.self)
    }
}
