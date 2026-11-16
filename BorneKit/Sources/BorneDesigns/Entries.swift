import BorneCore
import Foundation
import WidgetKit

/// Timeline entry for weather-driven designs (weather, sun & moon).
public struct WeatherEntry: TimelineEntry, Sendable {
    public enum State: Sendable {
        case loaded(WeatherSnapshot, isStale: Bool)
        case noLocation
        case unavailable
    }

    public let date: Date
    public let state: State
    public let temperatureUnit: TemperatureUnit
    public let windUnit: WindUnit
    public let uses24Hour: Bool

    public init(date: Date, state: State, temperatureUnit: TemperatureUnit = .celsius,
                windUnit: WindUnit = .kmh, uses24Hour: Bool = true) {
        self.date = date
        self.state = state
        self.temperatureUnit = temperatureUnit
        self.windUnit = windUnit
        self.uses24Hour = uses24Hour
    }

    public static var sample: WeatherEntry {
        WeatherEntry(date: .now, state: .loaded(.sample, isStale: false))
    }
}

/// Timeline entry for clock designs.
public struct ClockEntry: TimelineEntry, Sendable {
    public let date: Date
    public let uses24Hour: Bool
    public let worldClocks: [WorldClock]

    public init(date: Date, uses24Hour: Bool = true, worldClocks: [WorldClock] = WorldClock.defaults) {
        self.date = date
        self.uses24Hour = uses24Hour
        self.worldClocks = worldClocks
    }

    public static var sample: ClockEntry { ClockEntry(date: .now) }
}

extension ClockEntry {
    /// One entry per minute, starting at the beginning of the current minute.
    public static func timeline(from now: Date, count: Int, uses24Hour: Bool, worldClocks: [WorldClock]) -> [ClockEntry] {
        let start = Date(timeIntervalSinceReferenceDate: (now.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
        return (0..<count).map { i in
            ClockEntry(date: start.addingTimeInterval(Double(i) * 60), uses24Hour: uses24Hour, worldClocks: worldClocks)
        }
    }
}

/// Timeline entry for calendar designs.
public struct CalendarEntry: TimelineEntry, Sendable {
    public let date: Date
    public let access: CalendarAccess
    /// Events from a day before `date` to about a week after it.
    public let events: [CalendarEvent]
    public let uses24Hour: Bool
    /// Supplies the first weekday and time zone.
    public let calendar: Calendar

    public init(date: Date, access: CalendarAccess, events: [CalendarEvent],
                uses24Hour: Bool = true, calendar: Calendar = .current) {
        self.date = date
        self.access = access
        self.events = events
        self.uses24Hour = uses24Hour
        self.calendar = calendar
    }

    public var showsEvents: Bool { access == .granted }

    public static var sample: CalendarEntry {
        CalendarEntry(date: .now, access: .granted, events: CalendarEvent.samples(around: .now))
    }

    public static func noAccess(at date: Date, calendar: Calendar = .current) -> CalendarEntry {
        CalendarEntry(date: date, access: .denied, events: [], calendar: calendar)
    }
}
