import BorneCore
import BorneDesigns
import WidgetKit
import os

private let log = Logger(subsystem: "dev.borne.widgets", category: "WeatherProvider")

/// Weather timeline: one entry from the shared cache/fetch, refreshed every 30 min.
struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (WeatherEntry) -> Void) {
        log.debug("snapshot family=\(String(describing: context.family), privacy: .public) size=\(context.displaySize.width, privacy: .public)x\(context.displaySize.height, privacy: .public)")
        if context.isPreview {
            completion(.sample)
            return
        }
        Task { completion(await Self.loadEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<WeatherEntry>) -> Void) {
        log.debug("timeline family=\(String(describing: context.family), privacy: .public) size=\(context.displaySize.width, privacy: .public)x\(context.displaySize.height, privacy: .public)")
        Task {
            let entry = await Self.loadEntry()
            let next = Date.now.addingTimeInterval(WeatherStore.freshness)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    static func loadEntry(now: Date = .now) async -> WeatherEntry {
        let settings = SettingsStore()
        let state: WeatherEntry.State
        do {
            let result = try await WeatherStore(settings: settings).load()
            state = .loaded(result.snapshot, isStale: result.isStale)
        } catch WeatherError.noLocation {
            state = .noLocation
        } catch {
            state = .unavailable
        }
        return WeatherEntry(
            date: now, state: state,
            temperatureUnit: settings.temperatureUnit,
            windUnit: settings.windUnit,
            uses24Hour: settings.uses24HourClock
        )
    }
}
