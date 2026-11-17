import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"), .messageChannel)
final class SessionTests: XCTestCase {
    @UITest
    func signsOutWhenTheSessionExpires(context: UITestContext) throws {
        let app = context.app
        #expect(app[AccountID.authStatus].label == "Signed in")

        try context.send(ExpireSession())

        #expect(app[AccountID.authStatus].label == "Signed out")
        #expect(!app[AccountID.signOutButton].exists)
    }

    @UITest
    func showsANewNameAsSoonAsItChanges(context: UITestContext) throws {
        try context.send(RenameUser(name: "Grace"))
        #expect(context.app[AccountID.userName].label == "Grace")

        try context.send(RenameUser(name: "Katherine"))
        #expect(context.app[AccountID.userName].label == "Katherine")
    }

    @UITest
    func signsOutAgainAfterARestart(context: UITestContext) throws {
        try context.send(ExpireSession())
        #expect(context.app[AccountID.authStatus].label == "Signed out")

        try context.relaunch()
        #expect(context.app[AccountID.authStatus].label == "Signed in")

        try context.send(ExpireSession())
        #expect(context.app[AccountID.authStatus].label == "Signed out")
    }
}
