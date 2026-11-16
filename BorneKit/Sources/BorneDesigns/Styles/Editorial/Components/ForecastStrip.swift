import BorneCore
import SwiftUI
import WidgetKit

/// Days across the top, each with symbol, high, a min–max range bar
/// scaled to the whole week, and the low.
struct ForecastStrip: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let days: [WeatherSnapshot.Day]
    let unit: TemperatureUnit
    let timeZone: TimeZone
    var barHeight: CGFloat = 26

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let lo = days.map(\.min).min() ?? 0
        let hi = days.map(\.max).max() ?? 1
        HStack(alignment: .top, spacing: 0) {
            ForEach(days, id: \.date) { day in
                VStack(spacing: 3) {
                    EditorialCaption(EditorialFormat.weekdayShort(day.date, timeZone), color: palette.primary)
                    Image(systemName: day.condition.symbolName)
                        .font(.system(size: 11))
                        .foregroundStyle(day.precipitationProbability >= 50 ? palette.rain : palette.secondary)
                        .frame(height: 13)
                    Text(unit.format(day.max))
                        .font(EditorialTheme.numeral(13, weight: .semibold))
                        .foregroundStyle(palette.primary)
                    RangeBar(low: day.min, high: day.max, weekLow: lo, weekHigh: hi, palette: palette)
                        .frame(width: 4, height: barHeight)
                    Text(unit.format(day.min))
                        .font(EditorialTheme.numeral(11))
                        .foregroundStyle(palette.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct RangeBar: View {
    let low: Double, high: Double, weekLow: Double, weekHigh: Double
    let palette: EditorialPalette

    var body: some View {
        GeometryReader { geo in
            let span = max(weekHigh - weekLow, 1)
            let top = geo.size.height * (1 - (high - weekLow) / span)
            let bottom = geo.size.height * (1 - (low - weekLow) / span)
            ZStack(alignment: .top) {
                Capsule().fill(palette.hairline)
                Capsule()
                    .fill(LinearGradient(colors: [palette.golden.opacity(0.9), palette.rain.opacity(0.9)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(height: max(bottom - top, 4))
                    .offset(y: top)
            }
        }
    }
}

#Preview {
    let s = WeatherSnapshot.sample
    ForecastStrip(days: Array(s.daily.dropFirst().prefix(6)), unit: .celsius, timeZone: s.timeZone)
        .frame(width: 330)
        .padding()
        .background(EditorialTheme.background)
}
