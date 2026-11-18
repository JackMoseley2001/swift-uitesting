import CoreLocation
import XCTest

/// The simulated locations to put back when tests finish.
@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
@MainActor
private enum PreviousLocations {
    static var locations: [XCUILocation?] = []
}

/// A trait that puts the device at a location for a test.
///
/// Create one with ``UITestTrait/location(latitude:longitude:)``.
@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
public struct LocationTrait: UITestTrait {
    /// The latitude of the location, in degrees. North is positive.
    public let latitude: Double

    /// The longitude of the location, in degrees. East is positive.
    public let longitude: Double

    /// Whether the latitude and the longitude are a place on the Earth.
    var isValid: Bool {
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    public func prepare(_ launch: inout LaunchConfiguration) throws {
        guard isValid else {
            throw LaunchSettingError(
                message: "There is no location with the latitude \(latitude) and the longitude \(longitude)")
        }
    }

    @MainActor
    public func willLaunch(_ context: UITestContext) async throws {
        PreviousLocations.locations.append(XCUIDevice.shared.location)
        XCUIDevice.shared.location = XCUILocation(
            location: CLLocation(latitude: latitude, longitude: longitude))
    }

    @MainActor
    public func tearDown(_ context: UITestContext) async throws {
        if let previous = PreviousLocations.locations.popLast() {
            XCUIDevice.shared.location = previous
        }
    }
}

@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
extension UITestTrait where Self == LocationTrait {
    /// Puts the device at a location for the test, and puts it back afterwards.
    ///
    /// This is the location that the system reports, so the app gets it from Core
    /// Location with no extra code. It is set before the app is launched. The app
    /// still needs the user's permission to read it: see ``UITestTrait/systemAlerts(_:for:)``.
    ///
    /// ```swift
    /// @UITest(traits: .location(latitude: 51.5074, longitude: -0.1278))
    /// func showsTheNearestShop(app: XCUIApplication) { /* ... */ }
    /// ```
    ///
    /// The test fails before the app is launched if the latitude is not between -90
    /// and 90, or the longitude is not between -180 and 180.
    ///
    /// - Parameters:
    ///   - latitude: The latitude of the location, in degrees. North is positive.
    ///   - longitude: The longitude of the location, in degrees. East is positive.
    public static func location(latitude: Double, longitude: Double) -> Self {
        LocationTrait(latitude: latitude, longitude: longitude)
    }
}
