import Foundation

public enum WeatherError: Error, Equatable {
    case noLocation
}

public struct WeatherResult: Sendable, Equatable {
    public var snapshot: WeatherSnapshot
    /// True when a refresh failed and older cached data is being shown.
    public var isStale: Bool
}

/// Serves weather for the active location, caching it in the App Group so
/// the app and every widget share one fetch per 30 minutes.
public actor WeatherStore {
    public static let freshness: TimeInterval = 30 * 60

    private let fetcher: WeatherFetching
    private let settings: SettingsStore
    private let cacheURL: URL
    private let now: @Sendable () -> Date

    public init(
        fetcher: WeatherFetching = OpenMeteoClient(),
        settings: SettingsStore = SettingsStore(),
        cacheURL: URL = AppGroup.containerURL.appending(path: "weather.json"),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fetcher = fetcher
        self.settings = settings
        self.cacheURL = cacheURL
        self.now = now
    }

    public func load(forceRefresh: Bool = false) async throws -> WeatherResult {
        guard let location = settings.activeLocation else { throw WeatherError.noLocation }

        let cached = readCache().flatMap { $0.location.coordinate.isNear(location.coordinate) ? $0 : nil }
        if let cached, !forceRefresh, now().timeIntervalSince(cached.fetchedAt) < Self.freshness {
            return WeatherResult(snapshot: cached, isStale: false)
        }

        do {
            var snapshot = try await fetcher.fetch(for: location)
            snapshot.fetchedAt = now()
            writeCache(snapshot)
            return WeatherResult(snapshot: snapshot, isStale: false)
        } catch {
            if let cached { return WeatherResult(snapshot: cached, isStale: true) }
            throw error
        }
    }

    /// Last cached snapshot regardless of age or location (for quick UI).
    public func cachedSnapshot() -> WeatherSnapshot? { readCache() }

    private func readCache() -> WeatherSnapshot? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
    }

    private func writeCache(_ snapshot: WeatherSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
