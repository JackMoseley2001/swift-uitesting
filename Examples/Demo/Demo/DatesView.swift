import SwiftUI
import UITestingCore

/// Date pickers in each style, each with a line of text that shows what it is set to.
struct DatesView: View {
    /// 14 November 2023 at 22:13, in the time zone of the device.
    private static let start: Date = {
        let components = DateComponents(year: 2023, month: 11, day: 14, hour: 22, minute: 13)
        return Calendar.current.date(from: components) ?? .now
    }()

    @State private var date = start
    @State private var dateAndTime = start
    @State private var calendar = start
    @State private var timeWheel = start
    @State private var dateWheel = start
    @State private var dateAndTimeWheel = start

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                    .accessibilityIdentifier(DatesID.datePicker)
                Text(Self.day(date))
                    .accessibilityIdentifier(DatesID.date)

                DatePicker("Date and time", selection: $dateAndTime)
                    .accessibilityIdentifier(DatesID.dateAndTimePicker)
                Text("\(Self.day(dateAndTime)) \(Self.time(dateAndTime))")
                    .accessibilityIdentifier(DatesID.dateAndTime)

                DatePicker("Time", selection: $timeWheel, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .accessibilityIdentifier(DatesID.timeWheelPicker)
                Text(Self.time(timeWheel))
                    .accessibilityIdentifier(DatesID.timeWheel)

                DatePicker("Calendar", selection: $calendar, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .accessibilityIdentifier(DatesID.calendarPicker)
                Text(Self.day(calendar))
                    .accessibilityIdentifier(DatesID.calendar)

                DatePicker("Date", selection: $dateWheel, displayedComponents: [.date])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .accessibilityIdentifier(DatesID.dateWheelPicker)
                Text(Self.day(dateWheel))
                    .accessibilityIdentifier(DatesID.dateWheel)

                DatePicker("Date and time", selection: $dateAndTimeWheel)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .accessibilityIdentifier(DatesID.dateAndTimeWheelPicker)
                Text("\(Self.day(dateAndTimeWheel)) \(Self.time(dateAndTimeWheel))")
                    .accessibilityIdentifier(DatesID.dateAndTimeWheel)
            }
            .font(.footnote)
            .padding()
        }
    }

    /// A date as year, month and day, which reads the same in every language.
    private static func day(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// A time as hours and minutes on a 24-hour clock.
    private static func time(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }
}
