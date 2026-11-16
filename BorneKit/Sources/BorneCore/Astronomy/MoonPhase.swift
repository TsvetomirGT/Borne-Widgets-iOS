import Foundation

/// Moon phase from a simple mean synodic-month model (accurate to ~half a day,
/// plenty for a widget glyph and phase name).
public struct MoonPhase: Sendable, Equatable {
    public enum Name: String, Sendable, CaseIterable {
        case newMoon = "New moon"
        case waxingCrescent = "Waxing crescent"
        case firstQuarter = "First quarter"
        case waxingGibbous = "Waxing gibbous"
        case fullMoon = "Full moon"
        case waningGibbous = "Waning gibbous"
        case lastQuarter = "Last quarter"
        case waningCrescent = "Waning crescent"
    }

    public static let synodicMonth = 29.530588853
    /// A known new moon: 2000-01-06 18:14 UTC.
    static let referenceNewMoon = Date(timeIntervalSince1970: 947_182_440)

    /// Days since the last new moon.
    public let age: Double
    /// Position in the cycle, 0 = new, 0.5 = full.
    public let fraction: Double
    /// Lit share of the disc, 0…1.
    public let illumination: Double
    public let name: Name

    public init(date: Date) {
        let days = date.timeIntervalSince(Self.referenceNewMoon) / 86_400
        let age = (days.truncatingRemainder(dividingBy: Self.synodicMonth) + Self.synodicMonth)
            .truncatingRemainder(dividingBy: Self.synodicMonth)
        let fraction = age / Self.synodicMonth
        self.age = age
        self.fraction = fraction
        self.illumination = (1 - cos(2 * .pi * fraction)) / 2
        self.name = switch fraction {
        case ..<0.0339: .newMoon
        case ..<0.2161: .waxingCrescent
        case ..<0.2839: .firstQuarter
        case ..<0.4661: .waxingGibbous
        case ..<0.5339: .fullMoon
        case ..<0.7161: .waningGibbous
        case ..<0.7839: .lastQuarter
        case ..<0.9661: .waningCrescent
        default: .newMoon
        }
    }

    public var isWaxing: Bool { fraction < 0.5 }
}
