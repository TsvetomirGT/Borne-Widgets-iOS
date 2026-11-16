import BorneCore
import SwiftUI
import WidgetKit

/// Unwraps a WeatherEntry's state into a snapshot, or shows the empty state.
struct WeatherContent<Content: View>: View {
    let entry: WeatherEntry
    @ViewBuilder var content: (WeatherSnapshot, Bool) -> Content

    var body: some View {
        switch entry.state {
        case .loaded(let snapshot, let isStale):
            content(snapshot, isStale)
        case .noLocation:
            EditorialEmptyState(message: "Open Borne to set a location")
        case .unavailable:
            EditorialEmptyState(message: "Weather unavailable", symbol: "cloud.slash")
        }
    }
}

/// "UPDATED 09:30" shown when we're displaying older cached data.
struct StaleNote: View {
    let snapshot: WeatherSnapshot
    let entry: WeatherEntry
    var body: some View {
        EditorialCaption(EditorialFormat.staleLabel(fetchedAt: snapshot.fetchedAt, now: entry.date,
                                                    zone: snapshot.timeZone, uses24Hour: entry.uses24Hour), size: 7)
    }
}

extension WeatherSnapshot {
    /// Chance of rain in the current hour.
    func rainChance(at now: Date) -> Int {
        hours(from: now, count: 1).first?.precipitationProbability ?? 0
    }
}
