#if os(iOS)
import UIKit
import XCTest

/// The device settings to put back when a test finishes.
@MainActor
private enum PreviousDeviceState {
    static var orientations: [UIDeviceOrientation] = []
    static var appearances: [XCUIDevice.Appearance] = []
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

/// A trait that runs a test in light or dark mode.
///
/// Create one with ``UITestTrait/appearance(_:)``.
public struct AppearanceTrait: UITestTrait {
    /// The appearance of the device during the test.
    public let appearance: XCUIDevice.Appearance

    @MainActor
    public func setUp(_ context: UITestContext) async throws {
        PreviousDeviceState.appearances.append(XCUIDevice.shared.appearance)
        XCUIDevice.shared.appearance = appearance
    }

    @MainActor
    public func tearDown(_ context: UITestContext) async throws {
        if let previous = PreviousDeviceState.appearances.popLast() {
            XCUIDevice.shared.appearance = previous
        }
    }
}

extension UITestTrait where Self == AppearanceTrait {
    /// Runs the test with the device in light or dark mode, and puts it back afterwards.
    ///
    /// The appearance is changed after the app has launched.
    ///
    /// - Parameter appearance: The appearance of the device during the test.
    public static func appearance(_ appearance: XCUIDevice.Appearance) -> Self {
        AppearanceTrait(appearance: appearance)
    }
}
#endif
