import BorneCore
import SwiftUI
import WidgetKit

/// The full-page almanac (iOS 27 `systemExtraLargePortrait`): today, a
/// 24-hour curve, the week as a table, sun & moon and the summary.
struct EditorialWeatherExtraLarge: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: WeatherEntry

    var body: some View {
        WeatherContent(entry: entry) { s, stale in
            let palette = EditorialPalette(mode, scheme)
            let unit = entry.temperatureUnit
            let now = entry.date
            let today = s.today(at: now)
            let conditions = s.currentConditions(at: now)
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(alignment: .top, spacing: 10) {
                    Text(unit.format(conditions.temperature))
                        .font(EditorialTheme.numeral(56, weight: .semibold))
                        .foregroundStyle(palette.primary)
                        .widgetAccentable()
                    Text(conditions.condition.text)
                        .font(EditorialTheme.italic(24))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 12)
                    Spacer(minLength: 4)
                    ExtraLargeWindMark(direction: s.current.windDirection, speed: entry.windUnit.format(s.current.windSpeed))
                }
                HStack(alignment: .top) {
                    StatLabel(title: "feels", value: unit.format(s.current.apparentTemperature))
                    Spacer()
                    if let today {
                        StatLabel(title: "high", value: unit.format(today.max))
                        Spacer()
                        StatLabel(title: "low", value: unit.format(today.min))
                        Spacer()
                    }
                    StatLabel(title: "rain", value: "\(s.rainChance(at: now))%", valueColor: palette.rain)
                    Spacer()
                    StatLabel(title: "humid", value: "\(s.current.humidity)%")
                    Spacer()
                    StatLabel(title: "uv", value: "\(Int(s.current.uvIndex.rounded()))")
                }

                // 24-hour curve
                SectionRule(title: EditorialTheme.curveTitle, note: "hatched = rain") {
                    if stale { StaleNote(snapshot: s, entry: entry) }
                }
                TemperatureCurve(hours: s.hours(from: now, count: EditorialTheme.curveHours + 1), unit: unit,
                                 timeZone: s.timeZone, uses24Hour: entry.uses24Hour,
                                 now: entry.date, nowTemperature: s.currentConditions(at: entry.date).temperature)
                    .frame(height: 84)

                // Week
                SectionRule(title: "the week")
                WeekTable(days: Array(([today].compactMap { $0 } + s.days(after: now, count: 6)).prefix(7)),
                          unit: unit, timeZone: s.timeZone, now: now)

                // Sun & moon
                if let today {
                    let phase = MoonPhase(date: now)
                    SectionRule(title: "sun & moon")
                    HStack(alignment: .bottom, spacing: 16) {
                        SunArc(sunrise: today.sunrise, sunset: today.sunset, now: now,
                               timeZone: s.timeZone, uses24Hour: entry.uses24Hour)
                            .frame(width: 150, height: 54)
                        MoonGlyph(phase: phase).frame(width: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(phase.name.rawValue)
                                .font(EditorialTheme.italic(15))
                                .foregroundStyle(palette.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            EditorialCaption("golden hour", size: 7)
                            Text(EditorialFormat.time(SunTimes.goldenHour(sunset: today.sunset), s.timeZone, uses24Hour: entry.uses24Hour))
                                .font(EditorialTheme.numeral(16, weight: .semibold))
                                .foregroundStyle(palette.golden)
                        }
                        Spacer(minLength: 0)
                    }
                }

                Spacer(minLength: 0)
                Text(WeatherSummary.sentence(for: s, now: now, unit: unit))
                    .font(EditorialTheme.italic(16))
                    .foregroundStyle(palette.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                HStack {
                    EditorialCaption(EditorialFormat.longDate(now, s.timeZone), size: 8)
                    Spacer()
                    EditorialCaption(s.location.name, size: 8, color: palette.primary)
                }
            }
        }
    }
}


/// One row per day with a horizontal range bar scaled across the week.
private struct WeekTable: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let days: [WeatherSnapshot.Day]
    let unit: TemperatureUnit
    let timeZone: TimeZone
    let now: Date

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let lo = days.map(\.min).min() ?? 0
        let hi = days.map(\.max).max() ?? 1
        VStack(spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.element.date) { index, day in
                HStack(spacing: 10) {
                    EditorialCaption(index == 0 ? "today" : EditorialFormat.weekdayShort(day.date, timeZone),
                                     size: 9, color: palette.primary)
                        .frame(width: 40, alignment: .leading)
                    Image(systemName: day.condition.symbolName)
                        .font(.system(size: 12))
                        .foregroundStyle(day.precipitationProbability >= 50 ? palette.rain : palette.secondary)
                        .frame(width: 18)
                    Text("\(day.precipitationProbability)%")
                        .font(EditorialTheme.label(8))
                        .foregroundStyle(day.precipitationProbability >= 50 ? palette.rain : palette.secondary)
                        .frame(width: 30, alignment: .trailing)
                    Text(unit.format(day.min))
                        .font(EditorialTheme.numeral(13))
                        .foregroundStyle(palette.secondary)
                        .frame(width: 30, alignment: .trailing)
                    HorizontalRange(low: day.min, high: day.max, weekLow: lo, weekHigh: hi, palette: palette)
                        .frame(height: 4)
                    Text(unit.format(day.max))
                        .font(EditorialTheme.numeral(13, weight: .semibold))
                        .foregroundStyle(palette.primary)
                        .frame(width: 30, alignment: .leading)
                }
            }
        }
    }
}

private struct HorizontalRange: View {
    let low: Double, high: Double, weekLow: Double, weekHigh: Double
    let palette: EditorialPalette

    var body: some View {
        GeometryReader { geo in
            let span = max(weekHigh - weekLow, 1)
            let x0 = geo.size.width * (low - weekLow) / span
            let x1 = geo.size.width * (high - weekLow) / span
            ZStack(alignment: .leading) {
                Capsule().fill(palette.hairline)
                Capsule()
                    .fill(LinearGradient(colors: [palette.rain.opacity(0.9), palette.golden.opacity(0.9)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(x1 - x0, 4))
                    .offset(x: x0)
            }
        }
    }
}

private struct ExtraLargeWindMark: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let direction: Double
    let speed: String

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        VStack(spacing: 3) {
            ZStack {
                Circle().strokeBorder(palette.hairline, lineWidth: 0.8)
                EditorialCaption("n", size: 6).offset(y: -12)
                Image(systemName: "location.north.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.golden)
                    .rotationEffect(.degrees(direction + 180))
            }
            .frame(width: 34, height: 34)
            EditorialCaption("wind · " + WindUnit.compass(direction), size: 7)
            EditorialCaption(speed, size: 7)
        }
    }
}
