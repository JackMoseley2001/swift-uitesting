#if os(iOS)
import UIKit
import XCTest

/// The device settings to put back when a test finishes.
@MainActor
private enum PreviousDeviceState {
    static var orientations: [UIDeviceOrientation] = []
}

/// A trait that rotates the device for a test.
///
/// Create one with ``UITestTrait/orientation(_:)``.
public struct OrientationTrait: UITestTrait {
    /// The orientation of the device during the test.
    public let orientation: UIDeviceOrientation

    @MainActor
    public func setUp(_ context: UITestContext) async throws {
        PreviousDeviceState.orientations.append(XCUIDevice.shared.orientation)
        XCUIDevice.shared.orientation = orientation
    }

    @MainActor
    public func tearDown(_ context: UITestContext) async throws {
        if let previous = PreviousDeviceState.orientations.popLast() {
            XCUIDevice.shared.orientation = previous
        }
    }
}

extension UITestTrait where Self == OrientationTrait {
    /// Rotates the device for the test, and puts it back afterwards.
    ///
    /// The device is rotated after the app has launched. The app only follows if it
    /// supports the orientation.
    ///
    /// - Parameter orientation: The orientation of the device during the test.
    public static func orientation(_ orientation: UIDeviceOrientation) -> Self {
        OrientationTrait(orientation: orientation)
    }
}
#endif
