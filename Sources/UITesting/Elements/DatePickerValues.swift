import Foundation

/// The parts of setting a date picker that do not need a running app.
enum DatePickerValues {
    /// Returns the name of a month as the month wheel of a date picker shows it.
    ///
    /// - Parameters:
    ///   - month: The month, from 1 for January to 12.
    ///   - locale: The language the picker is shown in.
    /// - Returns: The name, or `nil` if there is no such month.
    static func monthName(_ month: Int, locale: Locale) -> String? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let names = calendar.standaloneMonthSymbols
        return names.indices.contains(month - 1) ? names[month - 1] : nil
    }

    /// Returns the title of an hour on the hour wheel.
    ///
    /// - Parameters:
    ///   - hour: The hour, from 0 to 23.
    ///   - hasPeriod: Whether the picker has a wheel for AM and PM, in which case its
    ///     hours run from 1 to 12.
    static func hourTitle(_ hour: Int, hasPeriod: Bool) -> String {
        guard hasPeriod else { return String(format: "%02d", hour) }
        let onClock = hour % 12
        return "\(onClock == 0 ? 12 : onClock)"
    }

    /// Returns the title of a minute on the minute wheel, which has two digits.
    static func minuteTitle(_ minute: Int) -> String {
        String(format: "%02d", minute)
    }

    /// Returns the title of the period that an hour is in, as the period wheel shows it.
    static func periodTitle(forHour hour: Int, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        return hour < 12 ? formatter.amSymbol : formatter.pmSymbol
    }

    /// Returns the number that a wheel's value starts with, such as 10 for "10 o’clock".
    static func leadingNumber(in value: String) -> Int? {
        Int(value.prefix { $0.isNumber })
    }

    /// Returns which of a time picker's wheels is which, from the values they show.
    ///
    /// The wheel for AM and PM is the one whose value has no number. The hour comes
    /// before the minute, and both have to be numbers that an hour and a minute can be.
    ///
    /// - Returns: The positions of the wheels, or `nil` if the values are not those of a time picker.
    static func timeWheels(values: [String]) -> (hour: Int, minute: Int, period: Int?)? {
        let numbered = values.indices.filter { leadingNumber(in: values[$0]) != nil }
        let others = values.indices.filter { leadingNumber(in: values[$0]) == nil }
        guard numbered.count == 2, others.count <= 1, values.count <= 3 else { return nil }
        guard
            let hour = leadingNumber(in: values[numbered[0]]), (0...23).contains(hour),
            let minute = leadingNumber(in: values[numbered[1]]), (0...59).contains(minute)
        else { return nil }
        return (numbered[0], numbered[1], others.first)
    }

    /// Returns which of a calendar's two wheels is the year and which the month.
    ///
    /// The year is the one whose value is a number.
    ///
    /// - Returns: The positions of the wheels, or `nil` if the values are not a month and a year.
    static func monthAndYearWheels(values: [String]) -> (month: Int, year: Int)? {
        guard values.count == 2 else { return nil }
        switch (Int(values[0]), Int(values[1])) {
        case (nil, .some): return (0, 1)
        case (.some, nil): return (1, 0)
        default: return nil
        }
    }
}
