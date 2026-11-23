/// How one attempt to send a message to the app went.
enum MessageAttempt: Equatable {
    /// The app's receivers ran and returned.
    case handled

    /// The app is not connected.
    case noConnection

    /// The app is connected, and nothing in it is receiving this type of message.
    case noReceiver

    /// The app could not decode the message, or a receiver threw.
    case failed(String)

    /// The app was sent the message and did not answer in time.
    case noReply
}

/// Sends a message to the app, and describes what went wrong if it is not handled.
enum MessageSend {
    /// Sends a message until the app handles it or the timeout has passed.
    ///
    /// An app that has not connected yet, or has nothing receiving the message yet, is
    /// tried again, because both are things the app does a little after it launches or
    /// shows a screen. Anything else ends the wait: a message that reached a receiver
    /// is not sent a second time.
    ///
    /// - Parameters:
    ///   - message: The name of the message, as the test wrote it.
    ///   - isListening: Whether the test has somewhere for the app to connect.
    ///   - attempt: Sends the message once, waiting up to the given time for the answer.
    /// - Returns: `nil` if the app handled the message, and a description of the failure if not.
    static func failure(
        message: String,
        timeout: Duration,
        isListening: Bool,
        polling: ExpectationPolling = ExpectationPolling(),
        attempt: (Duration) -> MessageAttempt
    ) -> String? {
        let summary = "Could not send \(message)"
        guard isListening else {
            return "\(summary): the test does not have the messageChannel trait"
        }

        var last = MessageAttempt.noConnection
        _ = polling.wait(timeout: timeout) {
            last = attempt(timeout)
            return last != .noConnection && last != .noReceiver
        }

        let time = ExpectationFailure.describe(timeout)
        switch last {
        case .handled:
            return nil

        case .noConnection:
            return "\(summary): the app did not connect within \(time). "
                + "Is it running, and does it receive a message with onUITestMessage or UITestMessages?"

        case .noReceiver:
            return "\(summary): nothing in the app was receiving this message after \(time)"

        case .failed(let reason):
            return "The app failed to handle \(message): \(reason)"

        case .noReply:
            return "\(summary): the app did not finish handling it within \(time)"
        }
    }
}
