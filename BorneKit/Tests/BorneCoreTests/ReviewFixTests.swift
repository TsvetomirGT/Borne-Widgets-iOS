import Foundation
import Testing
@testable import BorneCore

// MARK: SingleFlight — overlapping callers share one execution

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var n = 0
    func bump() { lock.withLock { n += 1 } }
    var value: Int { lock.withLock { n } }
}

@Test func singleFlightCoalescesConcurrentCalls() async throws {
    let flight = SingleFlight<Int>()
    let counter = Counter()
    async let a = flight.run { counter.bump(); try await Task.sleep(for: .milliseconds(100)); return 42 }
    async let b = flight.run { counter.bump(); return 7 }
    let (x, y) = try await (a, b)
    #expect(x == 42 && y == 42)
    #expect(counter.value == 1)
}

@Test func singleFlightRunsAgainAfterCompletion() async throws {
    let flight = SingleFlight<Int>()
    let counter = Counter()
    _ = try await flight.run { counter.bump(); return 1 }
    _ = try await flight.run { counter.bump(); return 2 }
    #expect(counter.value == 2)
}

// MARK: Current location re-resolve policy

@Test func currentLocationNeedsRefreshWhenMissingOrOld() {
    let now = iso("2026-11-16T12:00:00Z")
    #expect(LocationRefreshPolicy.needsRefresh(resolvedAt: nil, now: now))
    #expect(!LocationRefreshPolicy.needsRefresh(resolvedAt: now.addingTimeInterval(-30 * 60), now: now))
    #expect(LocationRefreshPolicy.needsRefresh(resolvedAt: now.addingTimeInterval(-61 * 60), now: now))
}

@Test func resolvedAtPersists() {
    let d = freshDefaults()
    let date = iso("2026-11-16T12:00:00Z")
    SettingsStore(defaults: d).currentLocationResolvedAt = date
    #expect(SettingsStore(defaults: d).currentLocationResolvedAt == date)
}

// MARK: Stale cache shows the forecast hour, not the old "current"

@Test func currentConditionsUseFreshSnapshotAsIs() {
    let start = iso("2026-11-16T00:00:00Z")
    var s = WeatherSnapshot.make(hourlyStart: start, hour: { i in (Double(i), 0, .clear) })
    s.fetchedAt = iso("2026-11-16T09:00:00Z")
    let c = s.currentConditions(at: iso("2026-11-16T09:20:00Z"))
    #expect(c.temperature == 10 && c.condition == .cloudy)   // from `current`
}

@Test func currentConditionsFallBackToHourlyWhenOld() {
    let start = iso("2026-11-16T00:00:00Z")
    var s = WeatherSnapshot.make(hourlyStart: start, hour: { i in (Double(i), 0, .clear) })
    s.fetchedAt = iso("2026-11-16T03:00:00Z")
    let c = s.currentConditions(at: iso("2026-11-16T15:20:00Z"))
    #expect(c.temperature == 15 && c.condition == .clear)    // from hour 15
}

// MARK: Cancellation detection (URLSession throws URLError.cancelled)

@Test func cancellationErrorsAreRecognised() {
    #expect(CancellationError().isCancellation)
    #expect(URLError(.cancelled).isCancellation)
    #expect(!URLError(.notConnectedToInternet).isCancellation)
}
