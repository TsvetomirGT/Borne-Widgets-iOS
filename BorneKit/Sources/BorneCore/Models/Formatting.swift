import Foundation

public enum TemperatureUnit: String, Codable, Sendable, CaseIterable {
    case celsius, fahrenheit

    public var title: String { self == .celsius ? "Celsius" : "Fahrenheit" }

    public func value(_ celsius: Double) -> Double {
        self == .celsius ? celsius : celsius * 9 / 5 + 32
    }

    /// Rounded degrees with a trailing `°`; never renders `-0°`.
    public func format(_ celsius: Double) -> String {
        let rounded = Int(value(celsius).rounded())
        return "\(rounded)°"
    }
}

public enum WindUnit: String, Codable, Sendable, CaseIterable {
    case kmh, mph, ms

    public var title: String {
        switch self {
        case .kmh: "km/h"
        case .mph: "mph"
        case .ms: "m/s"
        }
    }

    public func format(_ kmh: Double) -> String {
        let value = switch self {
        case .kmh: kmh
        case .mph: kmh / 1.609344
        case .ms: kmh / 3.6
        }
        return "\(Int(value.rounded())) \(title)"
    }

    /// 8-point compass label for a direction in degrees (0 = north).
    public static func compass(_ degrees: Double) -> String {
        let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return points[Int((normalized / 45).rounded()) % 8]
    }
}
