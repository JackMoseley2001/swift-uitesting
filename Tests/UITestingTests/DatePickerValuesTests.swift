import Foundation
import Testing

@testable import UITesting

@Suite
struct DatePickerValuesTests {
    private let english = Locale(identifier: "en_US")
    private let french = Locale(identifier: "fr_FR")
    private let periods = ["AM", "PM"]

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
        let twelveHour = try #Testing::require(DatePickerValues.timeWheels(values: english, periodTitles: periods))
        #Testing::expect(twelveHour == (0, 1, 2))

        let periodFirst = try #Testing::require(
            DatePickerValues.timeWheels(values: ["오후", "10", "13"], periodTitles: ["오전", "오후"]))
        #Testing::expect(periodFirst == (1, 2, 0))

        let twentyFourHour = try #Testing::require(
            DatePickerValues.timeWheels(values: ["22", "13"], periodTitles: periods))
        #Testing::expect(twentyFourHour.hour == 0)
        #Testing::expect(twentyFourHour.minute == 1)
        #Testing::expect(twentyFourHour.period == nil)
    }

    @Test
    func wheelsThatAreNotATimeAreNotTaken() {
        #Testing::expect(DatePickerValues.timeWheels(values: ["November", "14", "2023"], periodTitles: periods) == nil)
        #Testing::expect(DatePickerValues.timeWheels(values: ["November", "2023"], periodTitles: periods) == nil)
        #Testing::expect(DatePickerValues.timeWheels(values: [], periodTitles: periods) == nil)
    }

    @Test
    func wheelForTheDayIsLeftOutOfTheTimeWheels() throws {
        let twelveHour = ["Tue, Nov 14", "10 o’clock", "13 minutes", "PM"]
        let withPeriod = try #Testing::require(DatePickerValues.timeWheels(values: twelveHour, periodTitles: periods))
        #Testing::expect(withPeriod == (1, 2, 3))

        let today = try #Testing::require(
            DatePickerValues.timeWheels(values: ["Today", "22", "13"], periodTitles: periods))
        #Testing::expect(today.hour == 1)
        #Testing::expect(today.minute == 2)
        #Testing::expect(today.period == nil)

        let numbered = try #Testing::require(
            DatePickerValues.timeWheels(values: ["14 nov.", "22", "13"], periodTitles: periods))
        #Testing::expect(numbered.hour == 1)
        #Testing::expect(numbered.period == nil)
    }

    @Test
    func periodTitlesAreThoseOfTheLanguage() {
        #Testing::expect(DatePickerValues.periodTitles(locale: english) == ["AM", "PM"])
    }

    @Test
    func dateWheelsAreToldApartByTheirValues() throws {
        let monthFirst = try #Testing::require(
            DatePickerValues.monthDayAndYearWheels(values: ["November", "14", "2023"]))
        #Testing::expect(monthFirst == (0, 1, 2))

        let dayFirst = try #Testing::require(
            DatePickerValues.monthDayAndYearWheels(values: ["14", "November", "2023"]))
        #Testing::expect(dayFirst == (1, 0, 2))

        let yearFirst = try #Testing::require(
            DatePickerValues.monthDayAndYearWheels(values: ["2023", "November", "14"]))
        #Testing::expect(yearFirst == (1, 2, 0))
    }

    @Test
    func wheelsThatAreNotADateAreNotTaken() {
        #Testing::expect(DatePickerValues.monthDayAndYearWheels(values: ["10 o’clock", "13 minutes", "PM"]) == nil)
        #Testing::expect(DatePickerValues.monthDayAndYearWheels(values: ["November", "2023"]) == nil)
        #Testing::expect(DatePickerValues.monthDayAndYearWheels(values: ["Tue, Nov 14", "22", "13"]) == nil)
        #Testing::expect(DatePickerValues.monthDayAndYearWheels(values: ["November", "14", "15"]) == nil)
        #Testing::expect(DatePickerValues.monthDayAndYearWheels(values: ["Tue, 14 Nov", "16", "45"]) == nil)
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

    // MARK: The wheel for the day

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .distantPast
    }

    private func dayWheel(locale: Locale? = nil) -> DatePickerValues.DayWheel {
        DatePickerValues.DayWheel(locale: locale ?? english, calendar: utc, today: day(2026, 11, 17))
    }

    @Test
    func dayWheelShowsTheDayOfTheWeekAndIsTurnedWithoutIt() {
        #Testing::expect(dayWheel().value(on: day(2023, 11, 14)) == "Tue, Nov 14")
        #Testing::expect(dayWheel().title(on: day(2023, 11, 14)) == "Nov 14")
    }

    @Test
    func dayWheelShowsTodayByNameAndIsTurnedToItByDate() {
        #Testing::expect(dayWheel().value(on: day(2026, 11, 17)) == "Today")
        #Testing::expect(dayWheel().title(on: day(2026, 11, 17)) == "Nov 17")
    }

    @Test
    func dayWheelIsOnTheNearestDateThatReadsTheSame() {
        let wheel = dayWheel()
        // 14 November is a Tuesday in 2023 and in 2028.
        #Testing::expect(wheel.date(showing: "Tue, Nov 14", nearestTo: day(2024, 2, 29)) == day(2023, 11, 14))
        #Testing::expect(wheel.date(showing: "Tue, Nov 14", nearestTo: day(2028, 1, 1)) == day(2028, 11, 14))
        #Testing::expect(wheel.date(showing: "Today", nearestTo: day(2024, 2, 29)) == day(2026, 11, 17))
    }

    @Test
    func dayWheelValueIsReadWhateverItsPunctuation() {
        let british = dayWheel(locale: Locale(identifier: "en_GB"))
        #Testing::expect(british.date(showing: "Tue, 14 Nov", nearestTo: day(2023, 10, 1)) == day(2023, 11, 14))
    }

    @Test
    func dayWheelValueThatIsNoDateNearbyIsNotRead() {
        #Testing::expect(dayWheel().date(showing: "mar. 14 nov.", nearestTo: day(2024, 2, 29)) == nil)
        #Testing::expect(dayWheel().date(showing: "10 o’clock", nearestTo: day(2024, 2, 29)) == nil)
    }

    @Test
    func pickerIsInTheLocaleOfTheDeviceWhenTheLaunchChoosesNone() {
        #Testing::expect(DatePickerValues.locale(launchArguments: [], device: english) == english)
        #Testing::expect(DatePickerValues.locale(launchArguments: ["--flag", "-AppleLocale"], device: english) == english)
    }

    @Test
    func pickerHasTheRegionOfTheLaunchAndTheLanguageOfTheDevice() {
        let locale = DatePickerValues.locale(launchArguments: ["--flag", "-AppleLocale", "fr_FR"], device: english)

        #Testing::expect(locale.region == "FR")
        #Testing::expect(locale.language.languageCode == "en")
        #Testing::expect(DatePickerValues.monthName(3, locale: locale) == "March")
    }

    @Test
    func pickerHasTheLanguageOfTheLaunch() {
        let language = DatePickerValues.locale(launchArguments: ["-AppleLanguages", "(fr)"], device: english)
        #Testing::expect(language.region == "US")
        #Testing::expect(DatePickerValues.monthName(3, locale: language) == "mars")

        let both = DatePickerValues.locale(
            launchArguments: ["-AppleLanguages", "(\"de\", en)", "-AppleLocale", "fr_FR"], device: english)
        #Testing::expect(both.region == "FR")
        #Testing::expect(DatePickerValues.monthName(3, locale: both) == "März")
    }

    @Test
    func laterLaunchArgumentReplacesAnEarlierOne() {
        let locale = DatePickerValues.locale(
            launchArguments: ["-AppleLocale", "fr_FR", "-AppleLocale", "en_GB"], device: english)

        #Testing::expect(locale.region == "GB")
        #Testing::expect(
            DatePickerValues.DayWheel(locale: locale, calendar: utc, today: day(2026, 11, 17))
                .title(on: day(2023, 11, 14)) == "14 Nov")
    }

    @Test
    func daysAreCountedBetweenDates() {
        let wheel = dayWheel()
        #Testing::expect(wheel.days(from: day(2023, 11, 14), to: day(2023, 11, 14)) == 0)
        #Testing::expect(wheel.days(from: day(2023, 11, 14), to: day(2024, 2, 29)) == 107)
        #Testing::expect(wheel.days(from: day(2024, 2, 29), to: day(2023, 12, 31)) == -60)
    }

    @Test
    func wheelIsDraggedAsFarAsThereIsRoom() {
        let reach = DatePickerValues.WheelReach(above: 650, below: 100)

        // Later rows are reached by dragging up, and there is room for 20 rows of 32 points.
        #Testing::expect(reach.move(by: 107) == .drag(rows: 20, points: 640))
        #Testing::expect(reach.move(by: 8) == .drag(rows: 8, points: 256))
        // Earlier rows are reached by dragging down, where there is room for 3.
        #Testing::expect(reach.move(by: -60) == .drag(rows: -3, points: -96))
    }

    @Test
    func rowsNearTheMiddleAreTapped() {
        let reach = DatePickerValues.WheelReach(above: 650, below: 100)

        #Testing::expect(reach.move(by: 0) == nil)
        #Testing::expect(reach.move(by: 1) == .tap(rows: 1))
        #Testing::expect(reach.move(by: -2) == .tap(rows: -2))
    }

    @Test
    func wheelWithNoRoomToDragIsTurnedByTaps() {
        let reach = DatePickerValues.WheelReach(above: 650, below: 70)

        #Testing::expect(reach.move(by: -60) == .tap(rows: -2))
    }

    @Test
    func rowHeightIsCorrectedFromHowFarADragTurnedTheWheel() {
        var reach = DatePickerValues.WheelReach(above: 650, below: 100)

        reach.learn(from: .drag(rows: 20, points: 640), turned: 16)
        #Testing::expect(reach.rowHeight == 40)

        // A tap, a wheel that did not turn and one that went the other way say nothing.
        reach.learn(from: .tap(rows: 2), turned: 1)
        reach.learn(from: .drag(rows: 10, points: 400), turned: 0)
        reach.learn(from: .drag(rows: 10, points: 400), turned: -3)
        #Testing::expect(reach.rowHeight == 40)

        // A wheel that was flung does not make a row smaller than it can be.
        reach.learn(from: .drag(rows: 3, points: 120), turned: 30)
        #Testing::expect(reach.rowHeight == 20)
    }

    /// A wheel that tests turn, which records the moves made on it.
    private final class Wheel {
        var date: Date
        var moves: [DatePickerValues.WheelMove] = []
        /// How many rows the wheel turns for each row a drag is meant to turn it.
        var slip = 1.0
        /// The last date the wheel can be turned to.
        var last: Date?

        init(on date: Date) { self.date = date }

        func perform(_ move: DatePickerValues.WheelMove, calendar: Calendar) {
            moves.append(move)
            var rows = move.rows
            if case .drag = move { rows = Int((Double(rows) * slip).rounded()) }
            var next = calendar.date(byAdding: .day, value: rows, to: date) ?? date
            if let last, next > last { next = last }
            date = next
        }
    }

    @Test
    func dayWheelIsTurnedUntilItIsOnTheDate() {
        let wheel = Wheel(on: day(2023, 11, 14))
        let reach = DatePickerValues.WheelReach(above: 650, below: 100)

        let end = dayWheel().turn(from: wheel.date, to: day(2024, 2, 29), reach: reach) { _ in
            wheel.date
        } perform: {
            wheel.perform($0, calendar: utc)
        }

        #Testing::expect(end == day(2024, 2, 29))
        #Testing::expect(
            wheel.moves == [
                .drag(rows: 20, points: 640), .drag(rows: 20, points: 640), .drag(rows: 20, points: 640),
                .drag(rows: 20, points: 640), .drag(rows: 20, points: 640), .drag(rows: 7, points: 224),
            ])
    }

    @Test
    func dayWheelThatTurnsLessThanItWasDraggedStillArrives() {
        let wheel = Wheel(on: day(2023, 11, 14))
        wheel.slip = 0.8
        let reach = DatePickerValues.WheelReach(above: 650, below: 650)

        let forward = dayWheel().turn(from: wheel.date, to: day(2024, 2, 29), reach: reach) { _ in
            wheel.date
        } perform: {
            wheel.perform($0, calendar: utc)
        }
        #Testing::expect(forward == day(2024, 2, 29))

        wheel.slip = 1.7
        let back = dayWheel().turn(from: wheel.date, to: day(2023, 12, 31), reach: reach) { _ in
            wheel.date
        } perform: {
            wheel.perform($0, calendar: utc)
        }
        #Testing::expect(back == day(2023, 12, 31))
    }

    @Test
    func dayWheelThatWillNotTurnAnyFurtherIsLeftWhereItStops() {
        let wheel = Wheel(on: day(2023, 11, 14))
        wheel.last = day(2023, 11, 30)
        let reach = DatePickerValues.WheelReach(above: 650, below: 100)

        let end = dayWheel().turn(from: wheel.date, to: day(2024, 2, 29), reach: reach) { _ in
            wheel.date
        } perform: {
            wheel.perform($0, calendar: utc)
        }

        #Testing::expect(end == day(2023, 11, 30))
        // One drag reaches the last date, and three more leave the wheel where it is.
        #Testing::expect(wheel.moves.count == 4)
    }

    @Test
    func dayWheelThatShowsNoDateIsLeftAlone() {
        var moves = 0

        let end = dayWheel().turn(
            from: day(2023, 11, 14), to: day(2024, 2, 29), reach: .init(above: 650, below: 100)
        ) { _ in
            nil
        } perform: { _ in
            moves += 1
        }

        #Testing::expect(end == day(2023, 11, 14))
        #Testing::expect(moves == 1)
    }
}
