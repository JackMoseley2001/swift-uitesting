import Foundation

/// A trait that launches the app in a time zone.
///
/// Create one with ``UITestTrait/timeZone(_:)``.
public struct TimeZoneTrait: UITestTrait {
    /// The identifier of the time zone, such as `"America/New_York"`.
    public let identifier: String

    public func prepare(_ launch: inout LaunchConfiguration) throws {
        guard let timeZone = TimeZone(identifier: identifier) else {
            throw LaunchSettingError(message: "There is no time zone with the identifier \"\(identifier)\"")
        }
        launch.setTimeZone(timeZone)
    }
}

extension UITestTrait where Self == TimeZoneTrait {
    /// Launches the app in a time zone.
    ///
    /// The app sees the time zone as `TimeZone.current`, with no extra code, so its
    /// calendars and date formatters use it. The device's own setting is not changed.
    ///
    /// ```swift
    /// @UITest(traits: .timeZone("Asia/Tokyo"))
    /// func showsTheMeetingInLocalTime(app: XCUIApplication) { /* ... */ }
    /// ```
    ///
    /// The test fails before the app is launched if there is no such time zone.
    ///
    /// - Parameter identifier: A time zone identifier, such as `"America/New_York"` or `"UTC"`.
    public static func timeZone(_ identifier: String) -> Self {
        TimeZoneTrait(identifier: identifier)
    }
}

/// A launch setting that a trait was given and cannot apply.
struct LaunchSettingError: Error, Equatable, CustomStringConvertible {
    /// What is wrong with the setting.
    var message: String

    var description: String { message }
}
