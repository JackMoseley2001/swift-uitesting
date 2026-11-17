import Foundation
import Testing

@testable import UITesting

@Suite
struct DatePickerValuesTests {
    private let english = Locale(identifier: "en_US")
    private let french = Locale(identifier: "fr_FR")

    @Test
    func monthNameIsInTheLanguageOfThePicker() {
        #Testing::expect(DatePickerValues.monthName(3, locale: english) == "March")
        #Testing::expect(DatePickerValues.monthName(12, locale: english) == "December")
        #Testing::expect(DatePickerValues.monthName(3, locale: french) == "mars")
    }

    @Test
    func thereIsNoMonthOutsideTheYear() {
        #Testing::expect(DatePickerValues.monthName(0, locale: english) == nil)
        #Testing::expect(DatePickerValues.monthName(13, locale: english) == nil)
    }

    @Test
    func hourIsOnATwelveHourClockWhenThePickerHasAPeriod() {
        #Testing::expect(DatePickerValues.hourTitle(0, hasPeriod: true) == "12")
        #Testing::expect(DatePickerValues.hourTitle(7, hasPeriod: true) == "7")
        #Testing::expect(DatePickerValues.hourTitle(12, hasPeriod: true) == "12")
        #Testing::expect(DatePickerValues.hourTitle(14, hasPeriod: true) == "2")
        #Testing::expect(DatePickerValues.hourTitle(23, hasPeriod: true) == "11")
    }

    @Test
    func hourHasTwoDigitsWhenThePickerHasNoPeriod() {
        #Testing::expect(DatePickerValues.hourTitle(0, hasPeriod: false) == "00")
        #Testing::expect(DatePickerValues.hourTitle(7, hasPeriod: false) == "07")
        #Testing::expect(DatePickerValues.hourTitle(14, hasPeriod: false) == "14")
    }

    @Test
    func minuteHasTwoDigits() {
        #Testing::expect(DatePickerValues.minuteTitle(5) == "05")
        #Testing::expect(DatePickerValues.minuteTitle(30) == "30")
    }

    @Test
    func periodIsMorningBeforeNoon() {
        #Testing::expect(DatePickerValues.periodTitle(forHour: 0, locale: english) == "AM")
        #Testing::expect(DatePickerValues.periodTitle(forHour: 11, locale: english) == "AM")
        #Testing::expect(DatePickerValues.periodTitle(forHour: 12, locale: english) == "PM")
        #Testing::expect(DatePickerValues.periodTitle(forHour: 23, locale: english) == "PM")
    }

    @Test
    func leadingNumberIsReadFromAWheelValue() {
        #Testing::expect(DatePickerValues.leadingNumber(in: "10 o’clock") == 10)
        #Testing::expect(DatePickerValues.leadingNumber(in: "05 minutes") == 5)
        #Testing::expect(DatePickerValues.leadingNumber(in: "PM") == nil)
        #Testing::expect(DatePickerValues.leadingNumber(in: "") == nil)
    }

    @Test
    func timeWheelsAreToldApartByTheirValues() throws {
        let english = ["10 o’clock", "13 minutes", "PM"]
        let twelveHour = try #Testing::require(DatePickerValues.timeWheels(values: english))
        #Testing::expect(twelveHour == (0, 1, 2))

        let periodFirst = try #Testing::require(DatePickerValues.timeWheels(values: ["오후", "10", "13"]))
        #Testing::expect(periodFirst == (1, 2, 0))

        let twentyFourHour = try #Testing::require(DatePickerValues.timeWheels(values: ["22", "13"]))
        #Testing::expect(twentyFourHour.hour == 0)
        #Testing::expect(twentyFourHour.minute == 1)
        #Testing::expect(twentyFourHour.period == nil)
    }

    @Test
    func wheelsThatAreNotATimeAreNotTaken() {
        #Testing::expect(DatePickerValues.timeWheels(values: ["November", "14", "2023"]) == nil)
        #Testing::expect(DatePickerValues.timeWheels(values: ["November", "2023"]) == nil)
        #Testing::expect(DatePickerValues.timeWheels(values: []) == nil)
    }

    @Test
    func yearWheelIsTheOneThatShowsANumber() throws {
        let monthFirst = try #Testing::require(DatePickerValues.monthAndYearWheels(values: ["November", "2023"]))
        #Testing::expect(monthFirst == (0, 1))

        let yearFirst = try #Testing::require(DatePickerValues.monthAndYearWheels(values: ["2023", "11月"]))
        #Testing::expect(yearFirst == (1, 0))

        #Testing::expect(DatePickerValues.monthAndYearWheels(values: ["10 o’clock", "13 minutes", "PM"]) == nil)
        #Testing::expect(DatePickerValues.monthAndYearWheels(values: ["2023", "2024"]) == nil)
    }
}
