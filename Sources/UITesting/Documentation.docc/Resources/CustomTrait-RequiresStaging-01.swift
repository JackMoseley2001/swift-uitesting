import Foundation
import UITesting
import XCTest

/// Runs a test against the staging server, and skips it where there is none.
struct RequiresStaging: UITestTrait {
    func prepare(_ launch: inout LaunchConfiguration) throws {
        guard let url = ProcessInfo.processInfo.environment["STAGING_URL"] else {
            throw XCTSkip("Needs a staging server. Set STAGING_URL to run it.")
        }
        launch.environment["API_URL"] = url
    }
}

extension UITestTrait where Self == RequiresStaging {
    /// Runs the test against the staging server, and skips it where there is none.
    static var requiresStaging: Self { RequiresStaging() }
}
