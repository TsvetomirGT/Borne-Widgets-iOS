import Foundation

extension CalendarEvent {
    /// A believable week of events for previews, the widget gallery and tests.
    public static func samples(around date: Date, calendar: Calendar = .current) -> [CalendarEvent] {
        let today = calendar.startOfDay(for: date)
        let blue = RGB(red: 0.27, green: 0.52, blue: 0.85)
        let orange = RGB(red: 0.93, green: 0.55, blue: 0.27)
        let green = RGB(red: 0.36, green: 0.68, blue: 0.45)
        let purple = RGB(red: 0.62, green: 0.45, blue: 0.85)

        func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(byAdding: DateComponents(day: day, hour: hour, minute: minute), to: today)!
        }
        func event(_ id: String, _ title: String, _ start: Date, _ end: Date,
                   allDay: Bool = false, _ color: RGB) -> CalendarEvent {
            CalendarEvent(id: id, title: title, start: start, end: end, isAllDay: allDay, color: color)
        }
        return [
            event("s1", "Design review", at(0, 15), at(0, 16), blue),
            event("s2", "Dinner with Maria", at(0, 19, 30), at(0, 21, 30), orange),
            event("s3", "Standup", at(1, 9, 30), at(1, 9, 45), blue),
            event("s4", "Gym", at(1, 18), at(1, 19), green),
            event("s5", "Trip to Plovdiv", at(2, 0), at(5, 0), allDay: true, purple),
            event("s6", "Dentist", at(2, 11), at(2, 11, 45), orange),
            event("s7", "Name day", at(4, 0), at(5, 0), allDay: true, green),
            event("s8", "Portfolio call", at(6, 16), at(6, 17), blue),
        ]
    }
}
