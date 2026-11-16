import BorneCore
import BorneDesigns
import EventKit
import Foundation
import Observation
import WidgetKit

/// App-wide state: settings mirrored for SwiftUI, plus live weather for previews.
@MainActor
@Observable
final class AppModel {
    private let settings = SettingsStore()
    private let store: WeatherStore
    private let locationService = LocationService()
    private let refreshFlight = SingleFlight<Void>()

    private(set) var weatherState: WeatherEntry.State = .loaded(.sample, isStale: false)
    private(set) var isUsingSampleWeather = true
    private(set) var isRefreshing = false
    var locationError: String?

    var locationMode: LocationMode { didSet { settings.locationMode = locationMode; settingsChanged(refetch: true) } }
    var temperatureUnit: TemperatureUnit { didSet { settings.temperatureUnit = temperatureUnit; settingsChanged() } }
    var windUnit: WindUnit { didSet { settings.windUnit = windUnit; settingsChanged() } }
    var uses24HourClock: Bool { didSet { settings.uses24HourClock = uses24HourClock; settingsChanged() } }
    var worldClocks: [WorldClock] { didSet { settings.worldClocks = worldClocks; settingsChanged() } }
    /// Calendar access and the user's events, for calendar previews.
    private(set) var calendarAccess: CalendarAccess = .notDetermined
    private(set) var calendarEvents: [CalendarEvent] = []
    private let calendarReader = EventKitCalendarReader()
    private let eventStore = EKEventStore()
    private(set) var currentLocation: SavedLocation?
    private(set) var manualLocation: SavedLocation?

    init() {
        store = WeatherStore(settings: settings)
        locationMode = settings.locationMode
        temperatureUnit = settings.temperatureUnit
        windUnit = settings.windUnit
        uses24HourClock = settings.uses24HourClock
        worldClocks = settings.worldClocks
        currentLocation = settings.currentLocation
        manualLocation = settings.manualLocation
        reloadCalendar()
        // EventKit posts this when events change in any calendar app.
        // (`eventStore` is kept alive so EventKit delivers it.)
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .EKEventStoreChanged) {
                self?.reloadCalendar()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    var activeLocation: SavedLocation? { locationMode == .current ? currentLocation : manualLocation }
    var isLocationDenied: Bool { locationService.isDenied }

    func weatherEntry(at date: Date = .now) -> WeatherEntry {
        WeatherEntry(date: date, state: weatherState, temperatureUnit: temperatureUnit,
                     windUnit: windUnit, uses24Hour: uses24HourClock)
    }

    func clockEntry(at date: Date = .now) -> ClockEntry {
        ClockEntry(date: date, uses24Hour: uses24HourClock, worldClocks: worldClocks)
    }

    /// Previews use the user's events when allowed, sample events otherwise,
    /// so the library always shows what the widget can look like.
    func calendarEntry(at date: Date = .now) -> CalendarEntry {
        calendarAccess == .granted
            ? CalendarEntry(date: date, access: .granted, events: calendarEvents, uses24Hour: uses24HourClock)
            : CalendarEntry(date: date, access: .granted, events: CalendarEvent.samples(around: date),
                            uses24Hour: uses24HourClock)
    }

    func reloadCalendar() {
        let now = Date.now
        calendarAccess = calendarReader.access
        calendarEvents = calendarReader.events(from: now.addingTimeInterval(-86_400), to: now.addingTimeInterval(8 * 86_400))
    }

    func requestCalendarAccess() async {
        _ = await EventKitCalendarReader.requestAccess()
        reloadCalendar()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Loads weather for previews; falls back to sample data so the library
    /// always looks complete, while widgets show honest empty states.
    func refresh(force: Bool = false) async {
        reloadCalendar()
        try? await refreshFlight.run { @MainActor in await self.performRefresh(force: force) }
    }

    private func performRefresh(force: Bool) async {
        isRefreshing = true
        defer { isRefreshing = false }
        var force = force
        // "Current location" follows the user: look it up again when stale.
        if locationMode == .current, !isLocationDenied,
           LocationRefreshPolicy.needsRefresh(resolvedAt: settings.currentLocationResolvedAt, now: .now) {
            let previous = currentLocation
            await resolveCurrentLocation()
            if let previous, let now = currentLocation, !previous.coordinate.isNear(now.coordinate) { force = true }
        }
        do {
            let result = try await store.load(forceRefresh: force)
            weatherState = .loaded(result.snapshot, isStale: result.isStale)
            isUsingSampleWeather = false
        } catch {
            weatherState = .loaded(.sample, isStale: false)
            isUsingSampleWeather = true
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// "Update current location" in Settings.
    func useCurrentLocation() async {
        await resolveCurrentLocation()
        guard locationError == nil else { return }
        if locationMode != .current { locationMode = .current } else { await refresh(force: true) }
    }

    private func resolveCurrentLocation() async {
        locationError = nil
        do {
            let location = try await locationService.requestCurrentLocation()
            currentLocation = location
            settings.currentLocation = location
            settings.currentLocationResolvedAt = .now
        } catch {
            locationError = error.localizedDescription
        }
    }

    func chooseCity(_ location: SavedLocation) {
        manualLocation = location
        settings.manualLocation = location
        if locationMode != .manual { locationMode = .manual } else { settingsChanged(refetch: true) }
    }

    func searchCities(_ query: String) async throws -> [SavedLocation] {
        try await OpenMeteoClient().searchCities(query)
    }

    private func settingsChanged(refetch: Bool = false) {
        if refetch {
            Task { await refresh(force: true) }
        } else {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
