import UITestingCore

/// Ends the session, as the server would when it expires.
struct ExpireSession: UITestMessage {}

/// Changes the name of the user who is signed in.
struct RenameUser: UITestMessage {
    var name: String
}
