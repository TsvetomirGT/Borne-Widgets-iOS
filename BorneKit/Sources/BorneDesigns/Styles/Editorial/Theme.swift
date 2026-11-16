import BorneCore
import SwiftUI
import WidgetKit

/// Design tokens for the Dark Editorial style: an almanac printed on slate.
public enum EditorialTheme {
    public static let background = Color(hex: 0x141A24)
    static let backgroundDeep = Color(hex: 0x0E131B)
    static let primary = Color(hex: 0xF2EFE8)
    static let secondary = Color(hex: 0x8C919A)
    static let hairline = Color(hex: 0xF2EFE8).opacity(0.18)
    static let contour = Color.white.opacity(0.04)
    static let rain = Color(hex: 0x6FA8DC)
    static let golden = Color(hex: 0xE8915A)
    static let gold = Color(hex: 0xB8975A)

    /// Light Editorial: the same almanac, printed in ink on warm paper.
    enum Light {
        static let paper = Color(hex: 0xF4EFE6)
        static let paperDeep = Color(hex: 0xEAE3D6)
        static let ink = Color(hex: 0x1B2230)
        static let secondary = Color(hex: 0x6B6F78)
        static let hairline = Color(hex: 0x1B2230).opacity(0.16)
        static let contour = Color(hex: 0x1B2230).opacity(0.05)
        static let rain = Color(hex: 0x2F6FA8)
        static let golden = Color(hex: 0xC8682E)
        static let brass = Color(hex: 0xA07D3E)
        static let moonLit = Color(hex: 0xFFFCF5)
        static let moonShadow = Color(hex: 0x3A4152)
    }

    static func numeral(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func italic(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif).italic()
    }

    static func label(_ size: CGFloat = 9) -> Font {
        .system(size: size, weight: .medium, design: .monospaced).smallCaps()
    }

    /// How far ahead the temperature curve looks, in hours after now.
    public static let curveHours = 6
    static let curveTitle = "next \(curveHours) hours"

    /// Tracking applied to small-caps labels.
    static let labelTracking: CGFloat = 1
}

/// Colors that adapt to the widget rendering mode and appearance: slate or
/// paper in full color, monochrome for tinted / clear home screens.
struct EditorialPalette {
    let background: Color
    let backgroundDeep: Color
    let contour: Color
    let primary: Color
    let secondary: Color
    let hairline: Color
    let rain: Color
    let golden: Color
    let gold: Color
    /// The moon's sunlit side is always the bright tone, whatever the paper.
    let moonLit: Color
    let moonShadow: Color
    let showsTexture: Bool

    let isFullColor: Bool

    /// A calendar's colour, toned toward the palette: a quarter of its
    /// saturation drawn off, slightly deeper on paper. Monochrome modes use
    /// the primary ink so tinted Home Screens stay legible.
    func eventColor(_ rgb: RGB) -> Color {
        guard isFullColor else { return primary }
        let gray = (rgb.red + rgb.green + rgb.blue) / 3
        let tone = { (c: Double) in c * 0.75 + gray * 0.25 }
        let depth = background == EditorialTheme.Light.paper ? 0.82 : 1.0
        return Color(red: tone(rgb.red) * depth, green: tone(rgb.green) * depth, blue: tone(rgb.blue) * depth)
    }

    init(_ mode: WidgetRenderingMode, _ scheme: ColorScheme) {
        isFullColor = mode == .fullColor
        if mode == .fullColor, scheme == .light {
            background = EditorialTheme.Light.paper
            backgroundDeep = EditorialTheme.Light.paperDeep
            contour = EditorialTheme.Light.contour
            primary = EditorialTheme.Light.ink
            secondary = EditorialTheme.Light.secondary
            hairline = EditorialTheme.Light.hairline
            rain = EditorialTheme.Light.rain
            golden = EditorialTheme.Light.golden
            gold = EditorialTheme.Light.brass
            moonLit = EditorialTheme.Light.moonLit
            moonShadow = EditorialTheme.Light.moonShadow
            showsTexture = true
        } else if mode == .fullColor {
            background = EditorialTheme.background
            backgroundDeep = EditorialTheme.backgroundDeep
            contour = EditorialTheme.contour
            primary = EditorialTheme.primary
            secondary = EditorialTheme.secondary
            hairline = EditorialTheme.hairline
            rain = EditorialTheme.rain
            golden = EditorialTheme.golden
            gold = EditorialTheme.gold
            moonLit = EditorialTheme.primary
            moonShadow = EditorialTheme.secondary.opacity(0.25)
            showsTexture = true
        } else {
            background = .clear
            backgroundDeep = .clear
            contour = .clear
            primary = .white
            secondary = .white.opacity(0.6)
            hairline = .white.opacity(0.25)
            rain = .white.opacity(0.85)
            golden = .white
            gold = .white.opacity(0.35)
            moonLit = .white
            moonShadow = .white.opacity(0.2)
            showsTexture = false
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Date/time strings for the Editorial style.
enum EditorialFormat {
    static func time(_ date: Date, _ zone: TimeZone, uses24Hour: Bool) -> String {
        format(date, zone, uses24Hour ? "HH:mm" : "h:mm")
    }

    /// Time and, in 12-hour mode, the AM/PM marker to set beside it.
    static func clockParts(_ date: Date, _ zone: TimeZone, uses24Hour: Bool) -> (time: String, meridiem: String?) {
        (time(date, zone, uses24Hour: uses24Hour), uses24Hour ? nil : meridiem(date, zone))
    }

    /// "updated 09:30", or "updated sat 09:30" when the data is from another day.
    static func staleLabel(fetchedAt: Date, now: Date, zone: TimeZone, uses24Hour: Bool) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        let t = time(fetchedAt, zone, uses24Hour: uses24Hour)
        if cal.isDate(fetchedAt, inSameDayAs: now) { return "updated \(t)" }
        return "updated \(format(fetchedAt, zone, "EEE").lowercased()) \(t)"
    }

    /// Short hour for dense axes: "14" (24h) or "2p" / "12a" (12h).
    static func compactHour(_ date: Date, _ zone: TimeZone, uses24Hour: Bool) -> String {
        if uses24Hour { return format(date, zone, "HH") }
        return format(date, zone, "h") + format(date, zone, "a").prefix(1).lowercased()
    }

    static func meridiem(_ date: Date, _ zone: TimeZone) -> String {
        format(date, zone, "a")
    }

    static func weekdayShort(_ date: Date, _ zone: TimeZone) -> String {
        format(date, zone, "EEE").uppercased()
    }

    static func longDate(_ date: Date, _ zone: TimeZone) -> String {
        format(date, zone, "EEEE, d MMMM").uppercased()
    }

    static func shortDate(_ date: Date, _ zone: TimeZone) -> String {
        format(date, zone, "EEE d MMM").uppercased()
    }

    static func hour(_ date: Date, _ zone: TimeZone, uses24Hour: Bool) -> String {
        format(date, zone, uses24Hour ? "HH:mm" : "ha")
    }

    private static func format(_ date: Date, _ zone: TimeZone, _ pattern: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = zone
        f.dateFormat = pattern
        return f.string(from: date)
    }
}
