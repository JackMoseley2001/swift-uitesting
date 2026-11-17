import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"), .messageChannel)
final class SessionTests: XCTestCase {
}
