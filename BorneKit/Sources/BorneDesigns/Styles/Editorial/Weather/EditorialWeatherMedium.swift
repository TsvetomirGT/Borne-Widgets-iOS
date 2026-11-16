import BorneCore
import SwiftUI
import WidgetKit

struct EditorialWeatherMedium: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: WeatherEntry

    /// Today's high/low sits beside feels-like and rain, so the curve never
    /// has to stand in for the day's extremes.
    nonisolated static let statTitles = ["feels", "rain", "hi/lo"]

    var body: some View {
        WeatherContent(entry: entry) { s, stale in
            let palette = EditorialPalette(mode, scheme)
            let unit = entry.temperatureUnit
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(unit.format(s.currentConditions(at: entry.date).temperature))
                        .font(EditorialTheme.numeral(50, weight: .semibold))
                        .foregroundStyle(palette.primary)
                        .widgetAccentable()
                    Text(s.currentConditions(at: entry.date).condition.text)
                        .font(EditorialTheme.italic(17))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    HStack(spacing: 8) {
                        StatLabel(title: Self.statTitles[0], value: unit.format(s.current.apparentTemperature), valueSize: 13)
                        StatLabel(title: Self.statTitles[1], value: "\(s.rainChance(at: entry.date))%", valueColor: palette.rain, valueSize: 13)
                        if let today = s.today(at: entry.date) {
                            StatLabel(title: Self.statTitles[2],
                                      value: unit.format(today.max) + "/" + unit.format(today.min), valueSize: 13)
                        }
                    }
                    Spacer(minLength: 4)
                    EditorialCaption(s.location.name, size: 8, color: palette.primary)
                }
                .frame(width: 128, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        EditorialCaption(EditorialTheme.curveTitle, size: 8)
                        Spacer(minLength: 0)
                        if stale { StaleNote(snapshot: s, entry: entry) }
                    }
                    Hairline()
                    TemperatureCurve(hours: s.hours(from: entry.date, count: EditorialTheme.curveHours + 1), unit: unit,
                                     timeZone: s.timeZone, uses24Hour: entry.uses24Hour,
                                 now: entry.date, nowTemperature: s.currentConditions(at: entry.date).temperature)
                }
            }
        }
    }
}
