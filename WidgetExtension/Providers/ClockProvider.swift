import BorneCore
import BorneDesigns
import WidgetKit

/// Clock timeline: an entry for each of the next 60 minutes.
struct ClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClockEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (ClockEntry) -> Void) {
        completion(Self.entries(from: .now, count: 1)[0])
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ClockEntry>) -> Void) {
        completion(Timeline(entries: Self.entries(from: .now, count: 60), policy: .atEnd))
    }

    static func entries(from now: Date, count: Int) -> [ClockEntry] {
        let settings = SettingsStore()
        return ClockEntry.timeline(from: now, count: count,
                                   uses24Hour: settings.uses24HourClock,
                                   worldClocks: settings.worldClocks)
    }
}
