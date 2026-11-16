import Foundation

public struct Coordinate: Codable, Sendable, Equatable, Hashable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Roughly within a kilometre — close enough to reuse cached weather.
    public func isNear(_ other: Coordinate) -> Bool {
        abs(latitude - other.latitude) < 0.01 && abs(longitude - other.longitude) < 0.01
    }
}

public struct SavedLocation: Codable, Sendable, Equatable, Hashable {
    public var name: String
    public var coordinate: Coordinate
    public var timeZoneID: String
    /// Disambiguating detail for search results, e.g. "Sofia-Capital, Bulgaria".
    public var region: String?

    public init(name: String, coordinate: Coordinate, timeZoneID: String, region: String? = nil) {
        self.name = name
        self.coordinate = coordinate
        self.timeZoneID = timeZoneID
        self.region = region
    }

    public var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
}
