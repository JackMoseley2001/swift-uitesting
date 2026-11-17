import UITesting
import XCTest

/// Sends the app messages while it is running, which the account example receives.
@UITestSuite(traits: .example(.account), .loggedIn(as: "Ada"), .animationsDisabled, .messageChannel)
final class MessageChannelTests: XCTestCase {
    @UITest
    func aTestCanExpireTheSessionWhileTheAppIsRunning(context: UITestContext) throws {
        let app = context.app
        #expect(app[AccountID.authStatus].label == "Signed in")

        try context.send(ExpireSession())

        #expect(app[AccountID.authStatus].label == "Signed out")
        #expect(!app[AccountID.signOutButton].exists)
    }

    @UITest
    func aMessageCarriesValues(context: UITestContext) throws {
        try context.send(RenameUser(name: "Grace"))
        #expect(context.app[AccountID.userName].label == "Grace")

        try context.send(RenameUser(name: "Katherine"))
        #expect(context.app[AccountID.userName].label == "Katherine")
    }

    @UITest
    func aRelaunchedAppReceivesMessagesToo(context: UITestContext) throws {
        try context.send(ExpireSession())
        #expect(context.app[AccountID.authStatus].label == "Signed out")

        try context.relaunch()
        #expect(context.app[AccountID.authStatus].label == "Signed in")

        try context.send(ExpireSession())
        #expect(context.app[AccountID.authStatus].label == "Signed out")
    }
}
