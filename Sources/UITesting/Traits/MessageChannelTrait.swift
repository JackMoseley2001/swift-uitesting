/// A trait that lets a test send messages to the app while it is running.
///
/// Create one with ``UITestTrait/messageChannel``.
public struct MessageChannelTrait: UITestTrait {
    public func prepare(_ launch: inout LaunchConfiguration) throws {
        // The port has to be in the launch, so the channel opens here and not in
        // `willLaunch(_:)`. Opening it again, for a relaunch or for a suite and a test
        // that both have the trait, gives the same port.
        launch.setMessagePort(try MessageHost.shared.start())
    }

    @MainActor
    public func tearDown(_ context: UITestContext) async throws {
        MessageHost.shared.stop()
    }
}

extension UITestTrait where Self == MessageChannelTrait {
    /// Opens a channel to the app, so that the test can send it messages while it is
    /// running, with ``UITestContext/send(_:within:filePath:line:)``.
    ///
    /// ```swift
    /// @UITestSuite(traits: .loggedIn(as: "Ada"), .messageChannel)
    /// final class SessionTests: XCTestCase {
    ///     @UITest
    ///     func signsOutWhenTheSessionExpires(context: UITestContext) throws {
    ///         try context.send(ExpireSession())
    ///
    ///         #expect(context.app[AccountID.authStatus].label == "Signed out")
    ///     }
    /// }
    /// ```
    ///
    /// The test listens on a port of the device's loopback interface, which nothing
    /// outside the device can reach, and launches the app with the port in its
    /// environment. The app connects the first time it asks to receive a message, with
    /// `onUITestMessage(_:perform:)` or `UITestMessages` from UITestingCore.
    ///
    /// The channel is the same for every launch in the test, so a relaunched app
    /// connects again. It is closed when the test finishes.
    public static var messageChannel: Self {
        MessageChannelTrait()
    }
}
