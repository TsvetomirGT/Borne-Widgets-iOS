import BorneCore
import SwiftUI
import WidgetKit

/// Local time with an analog face, then a typeset list of world clocks.
struct EditorialClockLarge: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: ClockEntry

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let zone = TimeZone.current
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                AnalogFace(date: entry.date, showsNumerals: false)
                    .frame(width: 96, height: 96)
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 2) {
                    EditorialCaption("local time", size: 8)
                    let local = EditorialFormat.clockParts(entry.date, zone, uses24Hour: entry.uses24Hour)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(local.time)
                            .font(EditorialTheme.numeral(44, weight: .semibold))
                            .foregroundStyle(palette.primary)
                            .monospacedDigit()
                            .widgetAccentable()
                        if let meridiem = local.meridiem { EditorialCaption(meridiem, size: 10) }
                    }
                    Text(entry.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(EditorialTheme.italic(15))
                        .foregroundStyle(palette.primary)
                }
                Spacer(minLength: 0)
            }
            HStack {
                EditorialCaption("world clocks", size: 8)
                Spacer()
            }
            Hairline()
            ForEach(entry.worldClocks) { clock in
                WorldClockRow(clock: clock, date: entry.date, uses24Hour: entry.uses24Hour)
                Hairline()
            }
            Spacer(minLength: 0)
        }
    }
}

private struct WorldClockRow: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let clock: WorldClock
    let date: Date
    let uses24Hour: Bool

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let zone = clock.timeZone
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        let hour = cal.component(.hour, from: date)
        let isDay = (6..<18).contains(hour)
        let offset = WorldClockRow.offsetLabel(zone, date)
        return HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text(clock.name)
                    .font(EditorialTheme.italic(17))
                    .foregroundStyle(palette.primary)
                EditorialCaption(offset + " · " + EditorialFormat.shortDate(date, zone), size: 7)
            }
            Spacer()
            Image(systemName: isDay ? "sun.max" : "moon")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(isDay ? palette.golden : palette.secondary)
            let parts = EditorialFormat.clockParts(date, zone, uses24Hour: uses24Hour)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(parts.time)
                    .font(EditorialTheme.numeral(24, weight: .semibold))
                    .foregroundStyle(palette.primary)
                    .monospacedDigit()
                if let meridiem = parts.meridiem { EditorialCaption(meridiem, size: 8) }
            }
            .frame(minWidth: 72, alignment: .trailing)
        }
    }

    /// Hours ahead/behind local time, e.g. "+9h", "−5h", "+5:30", "same time".
    static func offsetLabel(_ zone: TimeZone, _ date: Date) -> String {
        let diff = zone.secondsFromGMT(for: date) - TimeZone.current.secondsFromGMT(for: date)
        if diff == 0 { return "same time" }
        let sign = diff > 0 ? "+" : "−"
        let h = abs(diff) / 3600, m = abs(diff) % 3600 / 60
        return m == 0 ? "\(sign)\(h)h" : "\(sign)\(h):\(String(format: "%02d", m))"
    }
}
