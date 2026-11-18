import Foundation

/// The parts of setting a date picker that do not need a running app.
enum DatePickerValues {
    /// Returns the locale that an app shows its date pickers in, from the arguments it
    /// is launched with.
    ///
    /// A picker takes its region and its formats from the app's locale, which is the
    /// value after the last `-AppleLocale`, and its words from the app's language,
    /// which is the first value after the last `-AppleLanguages`. These are what the
    /// `locale(_:)` and `language(_:)` traits add. Whichever the arguments do not
    /// choose is that of the device.
    ///
    /// An app only shows a language that it is localised for, so the language can be
    /// wrong for an app that is not.
    ///
    /// - Parameters:
    ///   - launchArguments: The arguments the app is launched with.
    ///   - device: The locale of the device.
    static func locale(launchArguments: [String], device: Locale = .current) -> Locale {
        func value(after flag: String) -> String? {
            guard let index = launchArguments.lastIndex(of: flag), launchArguments.indices.contains(index + 1)
            else { return nil }
            return launchArguments[index + 1]
        }
        let region = value(after: "-AppleLocale").map(Locale.init(identifier:))
        let language = value(after: "-AppleLanguages")
            .flatMap { $0.split(separator: ",").first }
            .map { $0.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" } }
            .flatMap { $0.isEmpty ? nil : Locale(identifier: $0) }
        guard region != nil || language != nil else { return device }

        // The language is taken without its region, which would replace the locale's.
        var components = Locale.Components(locale: region ?? device)
        let words = (language ?? device).language
        components.languageComponents = Locale.Language.Components(
            languageCode: words.languageCode, script: words.script, region: nil)
        components.region = (region ?? device).region
        return Locale(components: components)
    }

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

    /// Returns the titles that the wheel for AM and PM can show.
    static func periodTitles(locale: Locale) -> [String] {
        [periodTitle(forHour: 0, locale: locale), periodTitle(forHour: 12, locale: locale)]
    }

    /// Returns which of a picker's wheels set the time, from the values they show.
    ///
    /// The wheel for AM and PM is the one whose value has no number. The hour comes
    /// before the minute, and both have to be numbers that an hour and a minute can be.
    ///
    /// A picker with the wheel style that shows a date as well has a wheel for the day
    /// before the others, which is left out. With three wheels, the first is the day
    /// if it is not AM or PM and the other two are the hour and the minute.
    ///
    /// - Parameters:
    ///   - values: The value of each wheel, in order.
    ///   - periodTitles: The titles that the wheel for AM and PM can show.
    /// - Returns: The positions of the wheels, or `nil` if the values are not those of a time picker.
    static func timeWheels(
        values: [String],
        periodTitles: [String]
    ) -> (hour: Int, minute: Int, period: Int?)? {
        var skipped = 0
        if values.count == 4 {
            skipped = 1
        } else if values.count == 3, !periodTitles.contains(values[0]),
            values.dropFirst().allSatisfy({ leadingNumber(in: $0) != nil })
        {
            skipped = 1
        }
        let values = Array(values.dropFirst(skipped))
        let numbered = values.indices.filter { leadingNumber(in: values[$0]) != nil }
        let others = values.indices.filter { leadingNumber(in: values[$0]) == nil }
        guard numbered.count == 2, others.count <= 1, values.count <= 3 else { return nil }
        guard
            let hour = leadingNumber(in: values[numbered[0]]), (0...23).contains(hour),
            let minute = leadingNumber(in: values[numbered[1]]), (0...59).contains(minute)
        else { return nil }
        return (numbered[0] + skipped, numbered[1] + skipped, others.first.map { $0 + skipped })
    }

    /// Returns which of a date picker's three wheels is the month, the day and the year.
    ///
    /// The month is the one whose value has no number, the year is the number that is
    /// too large to be a day or a minute, and the day is the other.
    ///
    /// - Returns: The positions of the wheels, or `nil` if the values are not a month, a day and a year.
    static func monthDayAndYearWheels(values: [String]) -> (month: Int, day: Int, year: Int)? {
        guard values.count == 3 else { return nil }
        let numbers = values.map(leadingNumber(in:))
        guard
            let month = numbers.firstIndex(of: nil),
            let day = numbers.firstIndex(where: { $0.map((1...31).contains) ?? false }),
            let year = numbers.firstIndex(where: { ($0 ?? 0) > 59 }),
            Set([month, day, year]).count == 3
        else { return nil }
        return (month, day, year)
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

    /// The wheel for the day in a picker that shows a date and a time, which shows a
    /// day as "Tue, Nov 14" and has no year.
    struct DayWheel {
        /// The language the picker is shown in.
        var locale: Locale
        /// The calendar that days are counted in.
        var calendar: Calendar
        /// The date that the wheel shows as "Today".
        var today: Date

        /// How far from the date asked for the wheel's own date is looked for. A day
        /// of the month falls on the same day of the week again after five years or
        /// more, so there is one match at most within this many days either side.
        static let furthestDay = 912

        init(locale: Locale, calendar: Calendar = .current, today: Date = .now) {
            self.locale = locale
            self.calendar = calendar
            self.calendar.locale = locale
            self.today = today
        }

        /// Returns the value the wheel has when it is on a date.
        func value(on date: Date) -> String {
            isToday(date) ? todayTitle : formatted(date, template: "EEEMMMd")
        }

        /// Returns whether a value that the wheel shows is the one for a date.
        ///
        /// Only letters and digits are compared, because the picker punctuates a day
        /// differently from a date formatter in some languages: "Tue, 14 Nov" for
        /// "Tue 14 Nov".
        func shows(_ value: String, on date: Date) -> Bool {
            Self.comparable(value) == Self.comparable(self.value(on: date))
        }

        private static func comparable(_ value: String) -> String {
            String(value.filter { $0.isLetter || $0.isNumber })
        }

        /// Returns the title to turn the wheel to for a date, which has no day of the
        /// week. Today has a title like any other day, though the wheel shows "Today".
        func title(on date: Date) -> String {
            formatted(date, template: "MMMd")
        }

        /// Returns the date the wheel is on, from the value it shows.
        ///
        /// The value has no year, so this is the date nearest to `target` that the
        /// wheel would show that way.
        ///
        /// - Returns: The date, or `nil` if no date within ``furthestDay`` days of
        ///   `target` is shown as `value`.
        func date(showing value: String, nearestTo target: Date) -> Date? {
            if shows(value, on: today) { return today }
            for distance in 0...Self.furthestDay {
                for offset in distance == 0 ? [0] : [distance, -distance] {
                    guard let date = calendar.date(byAdding: .day, value: offset, to: target) else { continue }
                    if shows(value, on: date) { return date }
                }
            }
            return nil
        }

        /// Returns how many days after one date another is. It is negative if the
        /// other date is earlier.
        func days(from start: Date, to target: Date) -> Int {
            let from = calendar.startOfDay(for: start)
            let to = calendar.startOfDay(for: target)
            return calendar.dateComponents([.day], from: from, to: to).day ?? 0
        }

        /// Turns the wheel from one date to another with moves of a finger, reading
        /// the wheel after each move to find out how far it went.
        ///
        /// A drag does not always turn the wheel by the number of rows it was meant
        /// to, so the next move is worked out from where the wheel is, and the height
        /// of a row is corrected from how far each drag turned it.
        ///
        /// - Parameters:
        ///   - start: The date the wheel is on.
        ///   - target: The date to turn it to.
        ///   - reach: How far a finger can move from the middle of the wheel.
        ///   - read: Returns the date the wheel is on, given the date it was meant
        ///     to reach, or `nil` if what it shows is not a date.
        ///   - perform: Makes a move on the wheel.
        /// - Returns: The date the wheel ended on, which is `target` unless the wheel
        ///   would not turn any further.
        func turn(
            from start: Date,
            to target: Date,
            reach: WheelReach,
            read: (_ expected: Date) -> Date?,
            perform: (WheelMove) -> Void
        ) -> Date {
            var reach = reach
            var current = start
            var stalls = 0
            for _ in 0..<Self.mostMoves {
                let remaining = days(from: current, to: target)
                guard remaining != 0, let move = reach.move(by: remaining) else { break }
                perform(move)
                let expected = calendar.date(byAdding: .day, value: move.rows, to: current) ?? target
                guard let landed = read(expected) else { break }
                let turned = days(from: current, to: landed)
                reach.learn(from: move, turned: turned)
                stalls = turned == 0 ? stalls + 1 : 0
                current = landed
                if stalls == Self.mostStalls { break }
            }
            return current
        }

        /// How many moves are made before giving up on a wheel.
        static let mostMoves = 80

        /// How many moves in a row can leave the wheel where it was. A wheel that
        /// does not turn is at the first or the last date its picker allows.
        static let mostStalls = 3

        private func isToday(_ date: Date) -> Bool {
            calendar.isDate(date, inSameDayAs: today)
        }

        private func formatted(_ date: Date, template: String) -> String {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.setLocalizedDateFormatFromTemplate(template)
            return formatter.string(from: date)
        }

        /// The word for today in the language of the picker.
        ///
        /// A date formatter only gives the word for the day that the clock says it
        /// is, so that is the day formatted, whichever day ``today`` is.
        private var todayTitle: String {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: .now)
        }
    }

    /// One move of a finger that turns a wheel.
    enum WheelMove: Equatable {
        /// A tap on a row near the middle of the wheel, which turns the wheel to it.
        /// The row is this many below the middle, or above it if negative.
        case tap(rows: Int)

        /// A slow drag from the middle of the wheel, this many points up the screen,
        /// or down it if negative, meant to turn the wheel by a number of rows.
        case drag(rows: Int, points: Double)

        /// How many rows the move is meant to turn the wheel by. Later rows are positive.
        var rows: Int {
            switch self {
            case .tap(let rows), .drag(let rows, _): rows
            }
        }
    }

    /// How far a finger can move from the middle of a wheel, and how far that turns it.
    struct WheelReach: Equatable {
        /// How far a finger can be dragged up the screen from the middle of the wheel, in points.
        var above: Double

        /// How far a finger can be dragged down the screen from the middle of the wheel, in points.
        var below: Double

        /// The height of a row of the wheel, in points.
        var rowHeight: Double = 32

        /// How many rows either side of the middle can be tapped.
        static let rowsToTap = 2

        /// The heights that a row is taken to be able to have.
        static let rowHeights = 20.0...60.0

        /// Returns the move that turns the wheel by a number of rows, or as near to
        /// that as one move can.
        ///
        /// Later rows are below the middle, so they are reached by dragging up.
        ///
        /// - Parameter rows: How many rows to turn the wheel by. Later rows are positive.
        /// - Returns: The move, or `nil` if there is nothing to turn.
        func move(by rows: Int) -> WheelMove? {
            guard rows != 0 else { return nil }
            let direction = rows > 0 ? 1 : -1
            let room = rows > 0 ? above : below
            let withinReach = Int(room / rowHeight)
            guard abs(rows) > Self.rowsToTap, withinReach > Self.rowsToTap else {
                return .tap(rows: direction * min(abs(rows), Self.rowsToTap))
            }
            let dragged = min(abs(rows), withinReach)
            return .drag(rows: direction * dragged, points: Double(direction * dragged) * rowHeight)
        }

        /// Corrects the height of a row from how far a drag turned the wheel.
        ///
        /// - Parameters:
        ///   - move: The move that was made.
        ///   - turned: How many rows the wheel turned by.
        mutating func learn(from move: WheelMove, turned: Int) {
            guard case .drag(let rows, _) = move, turned != 0, (turned > 0) == (rows > 0) else { return }
            let height = rowHeight * Double(abs(rows)) / Double(abs(turned))
            rowHeight = min(max(height, Self.rowHeights.lowerBound), Self.rowHeights.upperBound)
        }
    }
}
