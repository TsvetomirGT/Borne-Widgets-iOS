import Foundation

public enum LocationMode: String, Codable, Sendable, CaseIterable {
    case current, manual
}

public struct WorldClock: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var name: String
    public var timeZoneID: String
    public var id: String { "\(name)|\(timeZoneID)" }

    public init(name: String, timeZoneID: String) {
        self.name = name
        self.timeZoneID = timeZoneID
    }

    public var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .gmt }

    public static let defaults: [WorldClock] = [
        .init(name: "London", timeZoneID: "Europe/London"),
        .init(name: "New York", timeZoneID: "America/New_York"),
        .init(name: "Tokyo", timeZoneID: "Asia/Tokyo"),
    ]
}

/// User settings shared by the app and every widget (App Group defaults).
// UserDefaults is documented as thread-safe but not marked Sendable.
public final class SettingsStore: @unchecked Sendable {
    public static let maxWorldClocks = 3

    private enum Key {
        static let locationMode = "locationMode"
        static let currentLocation = "currentLocation"
        static let currentLocationResolvedAt = "currentLocationResolvedAt"
        static let manualLocation = "manualLocation"
        static let temperatureUnit = "temperatureUnit"
        static let windUnit = "windUnit"
        static let uses24HourClock = "uses24HourClock"
        static let worldClocks = "worldClocks"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = AppGroup.defaults) {
        self.defaults = defaults
    }

    public var locationMode: LocationMode {
        get { enumValue(Key.locationMode) ?? .current }
        set { defaults.set(newValue.rawValue, forKey: Key.locationMode) }
    }

    /// Last location resolved from GPS by the app.
    public var currentLocation: SavedLocation? {
        get { decoded(Key.currentLocation) }
        set { encode(newValue, Key.currentLocation) }
    }

    /// When `currentLocation` was last resolved from GPS.
    public var currentLocationResolvedAt: Date? {
        get { defaults.object(forKey: Key.currentLocationResolvedAt) as? Date }
        set { defaults.set(newValue, forKey: Key.currentLocationResolvedAt) }
    }

    public var manualLocation: SavedLocation? {
        get { decoded(Key.manualLocation) }
        set { encode(newValue, Key.manualLocation) }
    }

    public var activeLocation: SavedLocation? {
        locationMode == .current ? currentLocation : manualLocation
    }

    public var temperatureUnit: TemperatureUnit {
        get { enumValue(Key.temperatureUnit) ?? .celsius }
        set { defaults.set(newValue.rawValue, forKey: Key.temperatureUnit) }
    }

    public var windUnit: WindUnit {
        get { enumValue(Key.windUnit) ?? .kmh }
        set { defaults.set(newValue.rawValue, forKey: Key.windUnit) }
    }

    public var uses24HourClock: Bool {
        get { defaults.object(forKey: Key.uses24HourClock) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.uses24HourClock) }
    }

    public var worldClocks: [WorldClock] {
        get { decoded(Key.worldClocks) ?? WorldClock.defaults }
        set { encode(Array(newValue.prefix(Self.maxWorldClocks)), Key.worldClocks) }
    }

    // MARK: Helpers

    private func enumValue<T: RawRepresentable>(_ key: String) -> T? where T.RawValue == String {
        defaults.string(forKey: key).flatMap(T.init(rawValue:))
    }

    private func decoded<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T?, _ key: String) {
        guard let value else { defaults.removeObject(forKey: key); return }
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
