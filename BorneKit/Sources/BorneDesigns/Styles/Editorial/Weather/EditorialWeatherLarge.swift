import BorneCore
import SwiftUI
import WidgetKit

/// The full almanac page: today, the next 18 hours, the week, sun & moon,
/// and a sentence summing it up.
struct EditorialWeatherLarge: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: WeatherEntry

    var body: some View {
        WeatherContent(entry: entry) { s, stale in
            let palette = EditorialPalette(mode, scheme)
            let unit = entry.temperatureUnit
            let now = entry.date
            let today = s.today(at: now)
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack(alignment: .top, spacing: 8) {
                    Text(unit.format(s.currentConditions(at: entry.date).temperature))
                        .font(EditorialTheme.numeral(42, weight: .semibold))
                        .foregroundStyle(palette.primary)
                        .widgetAccentable()
                    Text(s.currentConditions(at: entry.date).condition.text)
                        .font(EditorialTheme.italic(18))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 8)
                    Spacer(minLength: 4)
                    WindMark(direction: s.current.windDirection, speed: entry.windUnit.format(s.current.windSpeed))
                }
                HStack(alignment: .top) {
                    StatLabel(title: "feels", value: unit.format(s.current.apparentTemperature), valueSize: 13)
                    Spacer()
                    if let today {
                        StatLabel(title: "high", value: unit.format(today.max), valueSize: 13)
                        Spacer()
                        StatLabel(title: "low", value: unit.format(today.min), valueSize: 13)
                        Spacer()
                    }
                    StatLabel(title: "rain", value: "\(s.rainChance(at: now))%", valueColor: palette.rain, valueSize: 13)
                    Spacer()
                    StatLabel(title: "humid", value: "\(s.current.humidity)%", valueSize: 13)
                    Spacer()
                    StatLabel(title: "uv", value: "\(Int(s.current.uvIndex.rounded()))", valueSize: 13)
                }

                // Next hours
                HStack(spacing: 4) {
                    EditorialCaption(EditorialTheme.curveTitle + " · ", size: 7)
                    EditorialCaption("hatched = rain", size: 7, color: palette.rain)
                    Spacer()
                    if stale { StaleNote(snapshot: s, entry: entry) }
                }
                .padding(.top, 2)
                Hairline()
                TemperatureCurve(hours: s.hours(from: now, count: EditorialTheme.curveHours + 1), unit: unit,
                                 timeZone: s.timeZone, uses24Hour: entry.uses24Hour,
                                 now: entry.date, nowTemperature: s.currentConditions(at: entry.date).temperature)
                    .frame(height: 58)

                // Week
                ForecastStrip(days: s.days(after: now, count: 6), unit: unit, timeZone: s.timeZone, barHeight: 12)

                // Sun & moon
                if let today {
                    let phase = MoonPhase(date: now)
                    HStack(alignment: .bottom, spacing: 14) {
                        SunArc(sunrise: today.sunrise, sunset: today.sunset, now: now,
                               timeZone: s.timeZone, uses24Hour: entry.uses24Hour)
                            .frame(width: 120, height: 46)
                        MoonGlyph(phase: phase).frame(width: 34)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(phase.name.rawValue)
                                .font(EditorialTheme.italic(13))
                                .foregroundStyle(palette.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            EditorialCaption("golden", size: 7)
                            Text(EditorialFormat.time(SunTimes.goldenHour(sunset: today.sunset), s.timeZone, uses24Hour: entry.uses24Hour))
                                .font(EditorialTheme.numeral(13, weight: .semibold))
                                .foregroundStyle(palette.golden)
                        }
                        Spacer(minLength: 0)
                    }
                }

                Spacer(minLength: 0)
                Text(WeatherSummary.sentence(for: s, now: now, unit: unit))
                    .font(EditorialTheme.italic(13))
                    .foregroundStyle(palette.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                HStack {
                    EditorialCaption(EditorialFormat.longDate(now, s.timeZone), size: 7)
                    Spacer()
                    EditorialCaption(s.location.name, size: 7, color: palette.primary)
                }
            }
        }
    }
}

/// Compass ring with an arrow pointing where the wind blows from.
private struct WindMark: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let direction: Double
    let speed: String

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        VStack(spacing: 2) {
            ZStack {
                Circle().strokeBorder(palette.hairline, lineWidth: 0.8)
                Image(systemName: "location.north.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(palette.golden)
                    .rotationEffect(.degrees(direction + 180))
            }
            .frame(width: 24, height: 24)
            EditorialCaption("wind · " + WindUnit.compass(direction), size: 7)
            EditorialCaption(speed, size: 7)
        }
    }
}
