import BorneCore
import SwiftUI
import WidgetKit

struct EditorialClockMedium: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: ClockEntry

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let zone = TimeZone.current
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: entry.date) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: entry.date)?.count ?? 365
        let week = calendar.component(.weekOfYear, from: entry.date)
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(EditorialFormat.time(entry.date, zone, uses24Hour: entry.uses24Hour))
                        .font(EditorialTheme.numeral(58, weight: .semibold))
                        .foregroundStyle(palette.primary)
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .widgetAccentable()
                    if !entry.uses24Hour {
                        EditorialCaption(EditorialFormat.meridiem(entry.date, zone), size: 11)
                    }
                }
                Text(entry.date.formatted(.dateTime.weekday(.wide)))
                    .font(EditorialTheme.italic(18))
                    .foregroundStyle(palette.primary)
                Spacer(minLength: 6)
                EditorialCaption(entry.date.formatted(.dateTime.day().month(.wide).year()), size: 9, color: palette.primary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 6) {
                StatLabel(title: "week", value: "\(week)", valueSize: 15, alignment: .trailing)
                StatLabel(title: "day", value: "\(dayOfYear)", valueSize: 15, alignment: .trailing)
                YearProgress(fraction: Double(dayOfYear) / Double(daysInYear))
                    .frame(width: 70, height: 3)
                EditorialCaption("\(Int(Double(dayOfYear) / Double(daysInYear) * 100))% of year", size: 7)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct YearProgress: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let fraction: Double
    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.hairline)
                Capsule().fill(palette.golden).frame(width: geo.size.width * fraction)
            }
        }
    }
}
