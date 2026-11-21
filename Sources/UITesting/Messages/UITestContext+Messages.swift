import Foundation
import XCTest

extension UITestContext {
    /// Sends a message to the app, and waits for the app to handle it.
    ///
    /// Use this to make something happen in the app that the test cannot do through
    /// the user interface, in the middle of a test:
    ///
    /// ```swift
    /// @UITest(traits: .loggedIn(as: "Ada"), .messageChannel)
    /// func signsOutWhenTheSessionExpires(context: UITestContext) throws {
    ///     try context.send(ExpireSession())
    ///
    ///     #expect(context.app[AccountID.authStatus].label == "Signed out")
    /// }
    /// ```
    ///
    /// The message is a `UITestMessage`, which the app receives with
    /// `onUITestMessage(_:perform:)` or `UITestMessages`. The test needs the
    /// ``UITestTrait/messageChannel`` trait.
    ///
    /// The call returns when the app has finished handling the message. It waits for
    /// the app to connect and to be receiving this type of message, so it can be the
    /// first thing a test does, and it works again after ``relaunch(with:within:)``.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - timeout: How long to wait for the app to handle the message. The default is
    ///     the test's ``UITestTrait/actionTimeout(_:)``.
    ///   - filePath: The file where a failure is recorded.
    ///   - line: The line where a failure is recorded.
    /// - Throws: ``RequirementFailedError`` if the app does not handle the message in
    ///   time, or throws while handling it. The failure is recorded at the line of the
    ///   call, and the test ends. An error from encoding the message is thrown as it is.
    public func send<Message: UITestMessage>(
        _ message: Message,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let body = try JSONEncoder().encode(message)
        let host = MessageHost.shared
        let failure = MessageSend.failure(
            message: Message.messageName,
            timeout: timeout ?? ActionTimeout.current,
            isListening: launch.environment[LaunchEnvironmentKey.messagePort] != nil,
            attempt: { host.send(Message.messageName, body: body, replyWithin: $0) }
        )
        if let failure {
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
    }
}
