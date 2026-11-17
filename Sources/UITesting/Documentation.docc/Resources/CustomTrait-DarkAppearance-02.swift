import UITesting
import XCTest

/// Switches the device to its dark appearance for a test.
struct DarkAppearance: UITestTrait {
    func setUp(_ context: UITestContext) async throws {
        XCUIDevice.shared.appearance = .dark
    }

    func tearDown(_ context: UITestContext) async throws {
        XCUIDevice.shared.appearance = .light
    }
}
