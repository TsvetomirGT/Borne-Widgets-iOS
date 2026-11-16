import Foundation
import Testing
@testable import BorneCore

private struct FetchFailed: Error {}

private final class FakeFetcher: WeatherFetching, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls = 0
    private var _fails = false
    var calls: Int { lock.withLock { _calls } }
    func failFromNowOn() { lock.withLock { _fails = true } }

    func fetch(for location: SavedLocation) async throws -> WeatherSnapshot {
        let fail = lock.withLock { () -> Bool in _calls += 1; return _fails }
        if fail { throw FetchFailed() }
        return .make(location: location, hourlyStart: iso("2026-11-16T00:00:00Z"))
    }
}

private final class Clock: @unchecked Sendable {
    private let lock = NSLock()
    private var _now = iso("2026-11-16T09:00:00Z")
    var now: Date { lock.withLock { _now } }
    func advance(minutes: Double) { lock.withLock { _now = _now.addingTimeInterval(minutes * 60) } }
}

private func makeStore(_ fetcher: FakeFetcher, _ settings: SettingsStore, _ clock: Clock) -> WeatherStore {
    let url = FileManager.default.temporaryDirectory.appending(path: "borne-\(UUID().uuidString).json")
    return WeatherStore(fetcher: fetcher, settings: settings, cacheURL: url, now: { clock.now })
}

private func manualSettings(_ location: SavedLocation) -> SettingsStore {
    let s = SettingsStore(defaults: freshDefaults())
    s.locationMode = .manual
    s.manualLocation = location
    return s
}

@Test func noLocationThrows() async {
    let store = makeStore(FakeFetcher(), SettingsStore(defaults: freshDefaults()), Clock())
    await #expect(throws: WeatherError.noLocation) { try await store.load() }
}

@Test func freshCacheSkipsFetch() async throws {
    let f = FakeFetcher(), c = Clock()
    let store = makeStore(f, manualSettings(sofia), c)
    _ = try await store.load()
    c.advance(minutes: 29)
    let r = try await store.load()
    #expect(f.calls == 1)
    #expect(!r.isStale)
}

@Test func expiredCacheRefetches() async throws {
    let f = FakeFetcher(), c = Clock()
    let store = makeStore(f, manualSettings(sofia), c)
    _ = try await store.load()
    c.advance(minutes: 31)
    _ = try await store.load()
    #expect(f.calls == 2)
}

@Test func forceRefreshRefetches() async throws {
    let f = FakeFetcher(), c = Clock()
    let store = makeStore(f, manualSettings(sofia), c)
    _ = try await store.load()
    _ = try await store.load(forceRefresh: true)
    #expect(f.calls == 2)
}

@Test func locationChangeRefetches() async throws {
    let f = FakeFetcher(), c = Clock()
    let settings = manualSettings(sofia)
    let store = makeStore(f, settings, c)
    _ = try await store.load()
    settings.manualLocation = tokyo
    c.advance(minutes: 1)
    let r = try await store.load()
    #expect(f.calls == 2)
    #expect(r.snapshot.location.name == "Tokyo")
}

@Test func cacheSurvivesNewStoreInstance() async throws {
    let f = FakeFetcher(), c = Clock()
    let settings = manualSettings(sofia)
    let url = FileManager.default.temporaryDirectory.appending(path: "borne-\(UUID().uuidString).json")
    _ = try await WeatherStore(fetcher: f, settings: settings, cacheURL: url, now: { c.now }).load()
    _ = try await WeatherStore(fetcher: f, settings: settings, cacheURL: url, now: { c.now }).load()
    #expect(f.calls == 1)
}

@Test func failureServesStale() async throws {
    let f = FakeFetcher(), c = Clock()
    let store = makeStore(f, manualSettings(sofia), c)
    _ = try await store.load()
    f.failFromNowOn()
    c.advance(minutes: 45)
    let r = try await store.load()
    #expect(r.isStale)
    #expect(r.snapshot.location == sofia)
}

@Test func failureWithoutCacheThrows() async {
    let f = FakeFetcher()
    f.failFromNowOn()
    let store = makeStore(f, manualSettings(sofia), Clock())
    await #expect(throws: FetchFailed.self) { try await store.load() }
}

@Test func failureAfterLocationChangeDoesNotServeOtherCity() async throws {
    let f = FakeFetcher(), c = Clock()
    let settings = manualSettings(sofia)
    let store = makeStore(f, settings, c)
    _ = try await store.load()
    f.failFromNowOn()
    settings.manualLocation = tokyo
    await #expect(throws: FetchFailed.self) { try await store.load() }
}
