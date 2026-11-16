import Foundation

/// Weather condition derived from a WMO weather interpretation code.
public enum WeatherCondition: String, Codable, Sendable, CaseIterable {
    case clear, mainlyClear, partlyCloudy, cloudy, fog
    case drizzle, freezingDrizzle, rain, heavyRain, freezingRain
    case snow, showers, snowShowers, thunderstorm, thunderstormHail

    public init(wmoCode: Int) {
        switch wmoCode {
        case 0: self = .clear
        case 1: self = .mainlyClear
        case 2: self = .partlyCloudy
        case 3: self = .cloudy
        case 45, 48: self = .fog
        case 51, 53, 55: self = .drizzle
        case 56, 57: self = .freezingDrizzle
        case 61, 63: self = .rain
        case 65: self = .heavyRain
        case 66, 67: self = .freezingRain
        case 71, 73, 75, 77: self = .snow
        case 80, 81, 82: self = .showers
        case 85, 86: self = .snowShowers
        case 95: self = .thunderstorm
        case 96, 99: self = .thunderstormHail
        default: self = .cloudy
        }
    }

    public var text: String {
        switch self {
        case .clear: "Clear"
        case .mainlyClear: "Mostly clear"
        case .partlyCloudy: "Partly cloudy"
        case .cloudy: "Cloudy"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .freezingDrizzle: "Freezing drizzle"
        case .rain: "Rain"
        case .heavyRain: "Heavy rain"
        case .freezingRain: "Freezing rain"
        case .snow: "Snow"
        case .showers: "Showers"
        case .snowShowers: "Snow showers"
        case .thunderstorm: "Thunderstorm"
        case .thunderstormHail: "Thunder & hail"
        }
    }

    public var symbolName: String {
        switch self {
        case .clear, .mainlyClear: "sun.max"
        case .partlyCloudy: "cloud.sun"
        case .cloudy: "cloud"
        case .fog: "cloud.fog"
        case .drizzle: "cloud.drizzle"
        case .freezingDrizzle, .freezingRain: "cloud.sleet"
        case .rain, .showers: "cloud.rain"
        case .heavyRain: "cloud.heavyrain"
        case .snow, .snowShowers: "cloud.snow"
        case .thunderstorm, .thunderstormHail: "cloud.bolt.rain"
        }
    }

    public var isSnow: Bool { self == .snow || self == .snowShowers }
}
