import BorneCore
import SwiftUI
import WidgetKit

struct EditorialSunMoonSmall: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: WeatherEntry

    var body: some View {
        WeatherContent(entry: entry) { s, _ in
            let palette = EditorialPalette(mode, scheme)
            let phase = MoonPhase(date: entry.date)
            VStack(alignment: .leading, spacing: 6) {
                if let today = s.today(at: entry.date) {
                    SunArc(sunrise: today.sunrise, sunset: today.sunset, now: entry.date,
                           timeZone: s.timeZone, uses24Hour: entry.uses24Hour, showsNowLabel: false)
                        .frame(height: 62)
                    HStack(alignment: .center, spacing: 10) {
                        MoonGlyph(phase: phase).frame(width: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(phase.name.rawValue)
                                .font(EditorialTheme.italic(13))
                                .foregroundStyle(palette.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            HStack(spacing: 4) {
                                EditorialCaption("golden", size: 7)
                                Text(EditorialFormat.time(SunTimes.goldenHour(sunset: today.sunset), s.timeZone, uses24Hour: entry.uses24Hour))
                                    .font(EditorialTheme.numeral(12, weight: .semibold))
                                    .foregroundStyle(palette.golden)
                            }
                        }
                    }
                } else {
                    EditorialEmptyState(message: "Weather unavailable", symbol: "cloud.slash")
                }
            }
        }
    }
}
