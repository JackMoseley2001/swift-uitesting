import UITestingCore

// Messages that a UI test sends to the account example while it is running. The
// test sends one and the app receives it, so both targets compile this file.

/// Ends the session, as the server would when it expires.
struct ExpireSession: UITestMessage {}

/// Changes the name of the user who is signed in.
struct RenameUser: UITestMessage {
    var name: String
}
