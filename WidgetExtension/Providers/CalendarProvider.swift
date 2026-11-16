import BorneCore
import BorneDesigns
import WidgetKit

/// Calendar timeline: redraw now, at each event start/end in the next day,
/// and at midnight; ask again within the hour so new events show up.
struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (CalendarEntry) -> Void) {
        // The widget gallery shows sample events, like weather shows sample data.
        completion(context.isPreview ? .sample : Self.entries(now: .now).first!)
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<CalendarEntry>) -> Void) {
        let now = Date.now
        let entries = Self.entries(now: now)
        // Ask again an hour from now at the latest (the last entry is the
        // next midnight, which may be many hours away).
        let refresh = min(entries.last?.date ?? now, now.addingTimeInterval(3600))
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    static func entries(now: Date) -> [CalendarEntry] {
        let reader = EventKitCalendarReader()
        let calendar = Calendar.current
        let uses24Hour = SettingsStore().uses24HourClock
        let access = reader.access
        let events = reader.events(from: now.addingTimeInterval(-86_400), to: now.addingTimeInterval(8 * 86_400))
        return CalendarLayout.reloadDates(events: events, now: now, calendar: calendar).map {
            CalendarEntry(date: $0, access: access, events: events, uses24Hour: uses24Hour, calendar: calendar)
        }
    }
}
