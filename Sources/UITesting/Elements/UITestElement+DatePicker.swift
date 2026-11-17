// The calendar and the wheels of a date picker are as iOS shows them, and so is the
// XCTest call that turns a wheel.
#if os(iOS)
import XCTest

extension UITestElement where Kind == ElementKinds.DatePicker {
    /// Chooses a date in the picker, once it exists and is enabled.
    ///
    /// ```swift
    /// try app[BookingID.datePicker].setDate(year: 2026, month: 3, day: 9)
    /// ```
    ///
    /// For a picker that shows a calendar, which is one with the `graphical` style or
    /// one with the `compact` style, this opens the calendar if it has to, turns the
    /// calendar's wheels to the month and the year, taps the day, and closes the
    /// calendar again.
    ///
    /// For a picker with the `wheel` style that shows a date only, it turns the wheels
    /// for the year, the month and the day.
    ///
    /// A picker with the `wheel` style that shows a time as well has a single wheel
    /// for the day, which shows it as "Tue, Nov 14". It takes a day up to 49 days from
    /// the one it is on, so it is turned in several steps to a date that is further
    /// away, and the app is given each date on the way. The wheel does not show the
    /// year, so the picker is taken to be on the date nearest to the one asked for
    /// that reads the same. That is right for a date within two years of the picker's
    /// own, and can be wrong for one further away.
    /// XCTest can only turn that wheel when the app runs in the language and region of
    /// the device.
    ///
    /// - Parameters:
    ///   - year: The year.
    ///   - month: The month, from 1 for January to 12.
    ///   - day: The day of the month.
    ///   - locale: The language the picker is shown in, which is where the name of the
    ///     month comes from. The default is the language of the device. Pass one if the
    ///     test launches the app in another language.
    ///   - timeout: How long to wait for the picker, and for its calendar to show. The
    ///     default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the picker is not ready in time, has
    ///   neither a calendar nor wheels for a date, or does not end up on the date. The failure is recorded at the line
    ///   of the call, and the test ends.
    public func setDate(
        year: Int,
        month: Int,
        day: Int,
        locale: Locale = .current,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let date = "\(year)-\(DatePickerValues.minuteTitle(month))-\(DatePickerValues.minuteTitle(day))"
        let intent = "set \(date) in"
        let summary = "Could not \(intent) \(accessibilityIdentifier)"
        let app = try owningApp(inOrderTo: intent, filePath: filePath, line: line)
        let popover = Self.popover(in: app)
        try wait(toBe: .enabled, inOrderTo: intent, within: timeout, filePath: filePath, line: line)
        guard let monthName = DatePickerValues.monthName(month, locale: locale) else {
            try fail("\(summary): there is no month \(month)", filePath: filePath, line: line)
        }

        let polling = ExpectationPolling()
        let timeout = timeout ?? ActionTimeout.current
        let showYears = "DatePicker.Show"
        let hideYears = "DatePicker.Hide"

        // A graphical picker has its calendar inside it. A compact one shows it over
        // the app when its date is pressed.
        let isInline = element.buttons[showYears].exists
        if !isInline, element.pickerWheels.count > 0 {
            try setDateOnWheels(
                year: year, month: month, day: day, locale: locale, summary: summary, filePath: filePath, line: line)
            return
        }
        var calendar = element
        if !isInline {
            let buttons = element.buttons
            (buttons.count > 1 ? buttons.element(boundBy: 1) : buttons.firstMatch).tap()
            // The calendar is found by a button that it keeps, because the element
            // has to be found again after the button that shows the years is renamed.
            let nextMonth = "DatePicker.NextMonth"
            let shown = Self.pickerInFront(in: app, containing: .button, identifier: nextMonth) {
                $0.buttons[nextMonth]
            }
            guard let shown else {
                try fail(
                    "\(summary): no calendar showed after its date was tapped. "
                        + "Is this a picker for a time only, or one with the wheel style?",
                    filePath: filePath,
                    line: line
                )
            }
            calendar = shown
        }

        calendar.buttons[showYears].tap()
        let wheels = calendar.pickerWheels
        _ = polling.wait(timeout: timeout, until: { wheels.count == 2 })
        let values = wheels.allElementsBoundByIndex.map { "\($0.value ?? "")" }
        guard let positions = DatePickerValues.monthAndYearWheels(values: values) else {
            try fail(
                "\(summary): the calendar did not show a wheel for the month and one for the year",
                filePath: filePath,
                line: line
            )
        }
        let monthWheel = wheels.element(boundBy: positions.month)
        let yearWheel = wheels.element(boundBy: positions.year)
        if "\(monthWheel.value ?? "")" != monthName {
            monthWheel.adjust(toPickerWheelValue: monthName)
        }
        if "\(yearWheel.value ?? "")" != "\(year)" {
            yearWheel.adjust(toPickerWheelValue: "\(year)")
        }
        calendar.buttons[hideYears].tap()

        let dayButton = calendar.collectionViews.buttons.containing(.staticText, identifier: "\(day)").firstMatch
        guard polling.wait(timeout: timeout, until: { dayButton.exists }) == .met else {
            try fail("\(summary): the calendar shows no day \(day) for that month", filePath: filePath, line: line)
        }
        dayButton.tap()
        let isChosen = polling.wait(timeout: .seconds(2), until: { dayButton.isSelected }) == .met

        if !isInline {
            popover.tap()
            _ = polling.wait(timeout: .seconds(2), until: { !popover.exists })
        }
        guard isChosen else {
            try fail("\(summary): the day was not selected after tapping it", filePath: filePath, line: line)
        }
    }

    /// Chooses a time in the picker, once it exists and is enabled.
    ///
    /// ```swift
    /// try app[BookingID.timePicker].setTime(hour: 14, minute: 30)
    /// ```
    ///
    /// This is for a picker with the `wheel` style, or one with the `compact` style,
    /// which shows its wheels when its time is pressed. It opens the wheels if it has
    /// to, turns them, and closes them again.
    ///
    /// - Parameters:
    ///   - hour: The hour, from 0 to 23, whether or not the picker shows AM and PM.
    ///   - minute: The minute.
    ///   - locale: The language the picker is shown in, which is where the names for AM
    ///     and PM come from. The default is the language of the device.
    ///   - timeout: How long to wait for the picker, and for its wheels to show. The
    ///     default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the picker is not ready in time, has no
    ///   wheels for a time, or does not end up on the time. The failure is recorded at
    ///   the line of the call, and the test ends.
    public func setTime(
        hour: Int,
        minute: Int,
        locale: Locale = .current,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let time = "\(DatePickerValues.minuteTitle(hour)):\(DatePickerValues.minuteTitle(minute))"
        let intent = "set \(time) in"
        let summary = "Could not \(intent) \(accessibilityIdentifier)"
        let app = try owningApp(inOrderTo: intent, filePath: filePath, line: line)
        let popover = Self.popover(in: app)
        try wait(toBe: .enabled, inOrderTo: intent, within: timeout, filePath: filePath, line: line)

        let polling = ExpectationPolling()
        let timeout = timeout ?? ActionTimeout.current

        // A picker with the wheel style has its wheels inside it. A compact one shows
        // them over the app when its time is pressed.
        let isInline = element.pickerWheels.count > 0
        var wheels = element.pickerWheels
        if !isInline {
            let buttons = element.buttons
            (buttons.count > 1 ? buttons.element(boundBy: buttons.count - 1) : buttons.firstMatch).tap()
            let shown = Self.pickerInFront(in: app, containing: .pickerWheel, identifier: nil) {
                $0.pickerWheels.firstMatch
            }
            guard let shown else {
                try fail(
                    "\(summary): no wheels showed after its time was tapped. "
                        + "Is this a picker for a date only?",
                    filePath: filePath,
                    line: line
                )
            }
            wheels = shown.pickerWheels
        }
        func values() -> [String] { wheels.allElementsBoundByIndex.map { "\($0.value ?? "")" } }

        let periods = DatePickerValues.periodTitles(locale: locale)
        guard let positions = DatePickerValues.timeWheels(values: values(), periodTitles: periods) else {
            if !isInline { popover.tap() }
            try fail(
                "\(summary): the picker's wheels are not those of a time. They show: "
                    + values().joined(separator: ", "),
                filePath: filePath,
                line: line
            )
        }
        let hasPeriod = positions.period != nil
        let onClock = Int(DatePickerValues.hourTitle(hour, hasPeriod: hasPeriod))
        if DatePickerValues.leadingNumber(in: values()[positions.hour]) != onClock {
            wheels.element(boundBy: positions.hour)
                .adjust(toPickerWheelValue: DatePickerValues.hourTitle(hour, hasPeriod: hasPeriod))
        }
        if DatePickerValues.leadingNumber(in: values()[positions.minute]) != minute {
            wheels.element(boundBy: positions.minute)
                .adjust(toPickerWheelValue: DatePickerValues.minuteTitle(minute))
        }
        if let period = positions.period {
            let title = DatePickerValues.periodTitle(forHour: hour, locale: locale)
            if values()[period] != title {
                wheels.element(boundBy: period).adjust(toPickerWheelValue: title)
            }
        }

        let end = values()
        if !isInline {
            popover.tap()
            _ = polling.wait(timeout: .seconds(2), until: { !popover.exists })
        }
        let isSet =
            DatePickerValues.leadingNumber(in: end[positions.hour]) == onClock
            && DatePickerValues.leadingNumber(in: end[positions.minute]) == minute
        guard isSet else {
            try fail(
                "\(summary): the wheels ended on: \(end.joined(separator: ", "))",
                filePath: filePath,
                line: line
            )
        }
    }

    /// Sets the date of a picker with the wheel style, which has its wheels inside it.
    private func setDateOnWheels(
        year: Int,
        month: Int,
        day: Int,
        locale: Locale,
        summary: String,
        filePath: StaticString,
        line: UInt
    ) throws {
        let wheels = element.pickerWheels
        func values() -> [String] { wheels.allElementsBoundByIndex.map { "\($0.value ?? "")" } }
        func failure(_ reason: String) -> String {
            "\(summary): \(reason). They show: \(values().joined(separator: ", "))"
        }

        let start = values()
        if let positions = DatePickerValues.monthDayAndYearWheels(values: start) {
            // The year is set first and the day last, because the days that the
            // picker accepts depend on the month and the year.
            let monthName = DatePickerValues.monthName(month, locale: locale) ?? ""
            func isOn(_ position: Int, _ number: Int) -> Bool {
                DatePickerValues.leadingNumber(in: values()[position]) == number
            }
            if !isOn(positions.year, year) {
                wheels.element(boundBy: positions.year).adjust(toPickerWheelValue: "\(year)")
            }
            if values()[positions.month] != monthName {
                wheels.element(boundBy: positions.month).adjust(toPickerWheelValue: monthName)
            }
            if !isOn(positions.day, day) {
                wheels.element(boundBy: positions.day).adjust(toPickerWheelValue: "\(day)")
            }
            // A day that the month does not have is turned back by the picker.
            let isSet = ExpectationPolling().wait(timeout: .seconds(2)) {
                isOn(positions.year, year) && values()[positions.month] == monthName && isOn(positions.day, day)
            }
            guard isSet == .met else {
                try fail(failure("the wheels did not end on the date"), filePath: filePath, line: line)
            }
            return
        }

        // A picker that shows a time as well has one wheel for the day, before the
        // wheels for the time.
        let periods = DatePickerValues.periodTitles(locale: locale)
        guard let time = DatePickerValues.timeWheels(values: start, periodTitles: periods), time.hour > 0 else {
            try fail(failure("the picker's wheels are not those of a date"), filePath: filePath, line: line)
        }
        let dayWheel = DatePickerValues.DayWheel(locale: locale)
        let parts = DateComponents(year: year, month: month, day: day, hour: 12)
        guard
            let target = dayWheel.calendar.date(from: parts),
            dayWheel.calendar.dateComponents([.month, .day], from: target) == DateComponents(month: month, day: day)
        else {
            try fail("\(summary): there is no such date", filePath: filePath, line: line)
        }
        guard let shown = dayWheel.date(showing: start[0], nearestTo: target) else {
            try fail(
                failure(
                    "the picker's wheel for the day shows no year, and no date within "
                        + "\(DatePickerValues.DayWheel.furthestDay) days of the one asked for reads as "
                        + "\"\(start[0])\" in the language \"\(locale.identifier)\""),
                filePath: filePath,
                line: line
            )
        }
        let wheel = wheels.element(boundBy: 0)
        for date in dayWheel.turns(from: shown, to: target) {
            wheel.adjust(toPickerWheelValue: dayWheel.title(on: date))
            let expected = dayWheel.value(on: date)
            let isTurned = ExpectationPolling().wait(timeout: .seconds(2)) {
                dayWheel.shows(values().first ?? "", on: date)
            }
            guard isTurned == .met else {
                try fail(
                    failure("the wheel for the day did not turn to \"\(expected)\""),
                    filePath: filePath,
                    line: line
                )
            }
        }
    }

    /// Waits for a date picker to show over an app, and returns it.
    ///
    /// Other pickers on the screen can have a calendar or wheels of their own. The one
    /// in front is the one whose part can be tapped, because the others are covered.
    ///
    /// - Parameters:
    ///   - type: The type of an element that the picker has to contain.
    ///   - identifier: The identifier of that element, if it has to have one.
    ///   - part: Returns the element inside a picker that shows whether it is in front.
    private static func pickerInFront(
        in app: XCUIApplication,
        containing type: XCUIElement.ElementType,
        identifier: String?,
        within timeout: Duration = .seconds(3),
        part: (XCUIElement) -> XCUIElement
    ) -> XCUIElement? {
        let pickers = app.datePickers.containing(type, identifier: identifier)
        let popover = popover(in: app)
        var found: XCUIElement?
        _ = ExpectationPolling().wait(timeout: timeout) {
            guard popover.exists else { return false }
            found = pickers.allElementsBoundByIndex.reversed().first { part($0).isHittable }
            return found != nil
        }
        return found
    }

    /// The area around a calendar or wheels shown over the app, which closes them when tapped.
    private static func popover(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["PopoverDismissRegion"].firstMatch
    }
}
#endif
