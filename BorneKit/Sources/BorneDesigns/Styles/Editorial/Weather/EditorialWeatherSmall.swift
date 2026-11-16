import BorneCore
import SwiftUI
import WidgetKit

struct EditorialWeatherSmall: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: WeatherEntry

    var body: some View {
        WeatherContent(entry: entry) { s, stale in
            let palette = EditorialPalette(mode, scheme)
            let today = s.today(at: entry.date)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(entry.temperatureUnit.format(s.currentConditions(at: entry.date).temperature))
                        .font(EditorialTheme.numeral(48, weight: .semibold))
                        .foregroundStyle(palette.primary)
                        .minimumScaleFactor(0.6)
                        .widgetAccentable()
                    Spacer(minLength: 0)
                    Image(systemName: s.currentConditions(at: entry.date).condition.symbolName)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(palette.secondary)
                        .padding(.top, 8)
                }
                Text(s.currentConditions(at: entry.date).condition.text)
                    .font(EditorialTheme.italic(17))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                if let today {
                    HStack(spacing: 10) {
                        StatLabel(title: "high", value: entry.temperatureUnit.format(today.max), valueSize: 13)
                        StatLabel(title: "low", value: entry.temperatureUnit.format(today.min), valueSize: 13)
                        StatLabel(title: "rain", value: "\(s.rainChance(at: entry.date))%", valueColor: palette.rain, valueSize: 13)
                    }
                }
                Spacer(minLength: 4)
                HStack {
                    EditorialCaption(s.location.name, size: 8, color: palette.primary)
                    Spacer(minLength: 0)
                    if stale { StaleNote(snapshot: s, entry: entry) }
                }
            }
        }
    }
}
