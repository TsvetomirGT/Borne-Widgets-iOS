import Foundation

/// An sRGB colour, kept Foundation-only so calendar data stays testable.
public struct RGB: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

/// One event from the user's calendars, as the widgets need it.
public struct CalendarEvent: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var start: Date
    public var end: Date
    public var isAllDay: Bool
    /// The colour of the calendar the event belongs to.
    public var color: RGB

    public init(id: String, title: String, start: Date, end: Date, isAllDay: Bool, color: RGB) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.color = color
    }

    /// Start of every day this event touches. An event ending exactly at
    /// midnight (like an all-day event) does not spill into the next day.
    public func days(in calendar: Calendar) -> [Date] {
        let first = calendar.startOfDay(for: start)
        let lastMoment = end > start ? end.addingTimeInterval(-1) : start
        let last = calendar.startOfDay(for: lastMoment)
        var days: [Date] = []
        var day = first
        while day <= last {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }
}

/// Whether the app (and so its widgets) may read the user's events.
public enum CalendarAccess: Sendable, Equatable {
    case granted, denied, notDetermined
}
