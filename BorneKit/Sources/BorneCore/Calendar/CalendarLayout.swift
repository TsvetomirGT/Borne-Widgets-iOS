import Foundation

/// Pure date math behind the calendar widgets. Every function takes the
/// `Calendar` to use, so first weekday and time zone come from the caller.
public enum CalendarLayout {
    /// The month containing `date` as rows of 7 days; `nil` pads the days
    /// outside the month. The first column is `calendar.firstWeekday`.
    public static func monthGrid(for date: Date, calendar: Calendar) -> [[Date?]] {
        guard let month = calendar.dateInterval(of: .month, for: date),
              let dayCount = calendar.range(of: .day, in: .month, for: date)?.count else { return [] }
        let leading = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: month.start))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    /// The 7 day starts of the week containing `date`.
    public static func week(containing date: Date, calendar: Calendar) -> [Date] {
        let day = calendar.startOfDay(for: date)
        let back = (calendar.component(.weekday, from: day) - calendar.firstWeekday + 7) % 7
        guard let start = calendar.date(byAdding: .day, value: -back, to: day) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// `days` consecutive days from the day of `from`, each with the events
    /// touching it: all-day events first, then by start time.
    public static func agenda(_ events: [CalendarEvent], from: Date, days: Int,
                              calendar: Calendar) -> [(day: Date, events: [CalendarEvent])] {
        let first = calendar.startOfDay(for: from)
        let byDay = Dictionary(grouping: events.flatMap { e in e.days(in: calendar).map { ($0, e) } }, by: \.0)
        return (0..<days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: first) else { return nil }
            let dayEvents = (byDay[day] ?? []).map(\.1).sorted {
                $0.isAllDay != $1.isAllDay ? $0.isAllDay : ($0.start, $0.title) < ($1.start, $1.title)
            }
            return (day, dayEvents)
        }
    }

    /// Events not yet over at `after`, soonest first.
    public static func upcoming(_ events: [CalendarEvent], after: Date, limit: Int) -> [CalendarEvent] {
        Array(events.filter { $0.end > after }.sorted { $0.start < $1.start }.prefix(limit))
    }

    /// Start of every day that has at least one event.
    public static func daysWithEvents(_ events: [CalendarEvent], calendar: Calendar) -> Set<Date> {
        Set(events.flatMap { $0.days(in: calendar) })
    }

    /// When a calendar widget should redraw: now, each event start or end in
    /// the next 24 hours, and the next midnight (so "today" moves on).
    public static func reloadDates(events: [CalendarEvent], now: Date, calendar: Calendar) -> [Date] {
        let horizon = now.addingTimeInterval(24 * 3600)
        let changes = events.flatMap { [$0.start, $0.end] }.filter { $0 > now && $0 <= horizon }
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        return Array(Set([now] + changes + [midnight].compactMap { $0 })).sorted()
    }
}
