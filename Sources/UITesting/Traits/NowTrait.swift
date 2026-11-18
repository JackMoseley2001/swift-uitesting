import Foundation

/// A trait that asks the app to treat a date as the current one.
///
/// Create one with ``UITestTrait/now(_:)-(Date)`` or ``UITestTrait/now(_:)-(String)``.
public struct NowTrait: UITestTrait {
    /// The date, as the test wrote it.
    enum Source: Sendable, Equatable {
        case date(Date)
        case iso8601(String)
    }

    let source: Source

    /// The date the app should treat as now, or `nil` if the trait was given text
    /// that is not a date.
    public var date: Date? {
        switch source {
        case .date(let date): date
        case .iso8601(let text): Self.date(iso8601: text)
        }
    }

    public func prepare(_ launch: inout LaunchConfiguration) throws {
        guard let date else {
            throw LaunchSettingError(
                message: "\"\(source.text)\" is not a date and time in ISO 8601 format, such as \"2026-03-14T09:30:00Z\"")
        }
        launch.setNow(date)
    }

    /// Reads a date and time in ISO 8601 format, with or without fractions of a second.
    static func date(iso8601 text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: text) { return date }
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter.date(from: text)
    }
}

extension NowTrait.Source {
    fileprivate var text: String {
        switch self {
        case .date(let date): "\(date)"
        case .iso8601(let text): text
        }
    }
}

extension UITestTrait where Self == NowTrait {
    /// Asks the app to treat a date as the current one.
    ///
    /// XCTest cannot change the clock of the device, so the app has to read the date:
    /// `LaunchTraits.current.now`, from UITestingCore, is the date of the test, or the
    /// date on the clock when no test fixed one. The date does not move while the
    /// app runs.
    ///
    /// ```swift
    /// @UITest(traits: .now(Date(timeIntervalSince1970: 1_773_480_600)))
    /// func showsTheTaskAsOverdue(app: XCUIApplication) { /* ... */ }
    /// ```
    ///
    /// - Parameter date: The date the app should use in place of the clock.
    public static func now(_ date: Date) -> Self {
        NowTrait(source: .date(date))
    }

    /// Asks the app to treat a date as the current one, written in ISO 8601 format.
    ///
    /// ```swift
    /// @UITest(traits: .now("2026-03-14T09:30:00Z"), .timeZone("Europe/London"))
    /// func showsTheTaskAsOverdue(app: XCUIApplication) { /* ... */ }
    /// ```
    ///
    /// The text has to say which time zone it is in, with `Z` or an offset such as
    /// `+09:00`. The test fails before the app is launched if it is not a date.
    ///
    /// - Parameter iso8601: A date and time, such as `"2026-03-14T09:30:00Z"`.
    public static func now(_ iso8601: String) -> Self {
        NowTrait(source: .iso8601(iso8601))
    }
}
