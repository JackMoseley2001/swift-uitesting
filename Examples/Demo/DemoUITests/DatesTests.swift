import UITesting
import XCTest

// The library sets date pickers on iOS only.
#if os(iOS)
@UITestSuite(traits: .example(.dates), .animationsDisabled)
final class DatesTests: XCTestCase {
    @UITest
    func setsADateInACompactPicker(app: XCUIApplication) throws {
        #expect(app[DatesID.date].label == "2023-11-14")

        try app[DatesID.datePicker].setDate(year: 2026, month: 3, day: 9)

        #expect(app[DatesID.date].label == "2026-03-09")
    }

    @UITest
    func setsADateInTheSameMonth(app: XCUIApplication) throws {
        try app[DatesID.datePicker].setDate(year: 2023, month: 11, day: 30)

        #expect(app[DatesID.date].label == "2023-11-30")
    }

    @UITest
    func setsADateAndATimeInACompactPicker(app: XCUIApplication) throws {
        let picker = app[DatesID.dateAndTimePicker]
        #expect(app[DatesID.dateAndTime].label == "2023-11-14 22:13")

        try picker.setTime(hour: 7, minute: 5)
        #expect(app[DatesID.dateAndTime].label == "2023-11-14 07:05")

        try picker.setDate(year: 2024, month: 2, day: 29)
        #expect(app[DatesID.dateAndTime].label == "2024-02-29 07:05")
    }

    @UITest
    func setsATimeOnWheels(app: XCUIApplication) throws {
        try app[DatesID.timeWheelPicker].setTime(hour: 0, minute: 30)
        #expect(app[DatesID.timeWheel].label == "00:30")

        try app[DatesID.timeWheelPicker].setTime(hour: 14, minute: 0)
        #expect(app[DatesID.timeWheel].label == "14:00")
    }

    @UITest
    func setsADateInACalendar(app: XCUIApplication) throws {
        let picker = try app[DatesID.calendarPicker].scrollIntoView()

        try picker.setDate(year: 2025, month: 12, day: 25)

        #expect(app[DatesID.calendar].label == "2025-12-25")
    }

    @UITest
    func setsADateOnWheels(app: XCUIApplication) throws {
        let picker = try app[DatesID.dateWheelPicker].scrollIntoView()
        #expect(app[DatesID.dateWheel].label == "2023-11-14")

        try picker.setDate(year: 2024, month: 2, day: 29)
        #expect(app[DatesID.dateWheel].label == "2024-02-29")

        try picker.setDate(year: 2024, month: 2, day: 1)
        #expect(app[DatesID.dateWheel].label == "2024-02-01")
    }

    @UITest
    func setsATimeOnWheelsThatShowADateAsWell(app: XCUIApplication) throws {
        let picker = try app[DatesID.dateAndTimeWheelPicker].scrollIntoView()

        try picker.setTime(hour: 7, minute: 5)

        #expect(app[DatesID.dateAndTimeWheel].label == "2023-11-14 07:05")
    }

    @UITest
    func setsADateOnWheelsThatShowATimeAsWell(app: XCUIApplication) throws {
        let picker = try app[DatesID.dateAndTimeWheelPicker].scrollIntoView()

        // The wheel for the day is turned in steps to a date this far away.
        try picker.setDate(year: 2024, month: 2, day: 29)
        #expect(app[DatesID.dateAndTimeWheel].label == "2024-02-29 22:13")

        try picker.setDate(year: 2023, month: 12, day: 31)
        try picker.setTime(hour: 9, minute: 0)
        #expect(app[DatesID.dateAndTimeWheel].label == "2023-12-31 09:00")
    }

    @UITest(traits: .locale("en_GB"))
    func setsATimeOnATwentyFourHourClock(app: XCUIApplication) throws {
        try app[DatesID.timeWheelPicker].setTime(hour: 7, minute: 5)
        #expect(app[DatesID.timeWheel].label == "07:05")

        let picker = try app[DatesID.dateAndTimeWheelPicker].scrollIntoView()
        try picker.setTime(hour: 16, minute: 45)
        #expect(app[DatesID.dateAndTimeWheel].label == "2023-11-14 16:45")
    }
}
#endif
