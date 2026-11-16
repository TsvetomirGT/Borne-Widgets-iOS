import Foundation

extension WeatherSnapshot {
    /// Realistic, now-relative data used for widget gallery previews,
    /// placeholders and SwiftUI previews. Never shown as real weather.
    public static var sample: WeatherSnapshot {
        let calendar = Calendar.current
        let now = Date.now
        let startOfDay = calendar.startOfDay(for: now)
        let currentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let hourIndex = Int(currentHour.timeIntervalSince(startOfDay) / 3600)

        // 13° now, a gentle rise to ~14° over the next hours, cooling to
        // ~9° overnight, with a rainy stretch 12–17 hours out.
        let hourly = (0..<48).map { i -> Hour in
            let ahead = i - hourIndex
            let temp = 13 + 1.2 * sin(Double(ahead) / 8 * .pi) - Double(max(0, ahead - 6)) * 0.3
            let rainy = (12...17).contains(ahead)
            return Hour(
                time: startOfDay.addingTimeInterval(Double(i) * 3600),
                temperature: temp,
                precipitationProbability: rainy ? 70 : 10,
                precipitation: rainy ? 0.8 : 0,
                condition: rainy ? .rain : .cloudy
            )
        }

        let highs: [(Double, Double, WeatherCondition, Int)] = [
            (11, 17, .cloudy, 20), (12, 15, .rain, 80), (10, 15, .showers, 60), (10, 13, .rain, 70),
            (9, 15, .rain, 60), (11, 14, .drizzle, 50), (9, 12, .rain, 70),
        ]
        let daily = highs.enumerated().map { i, d -> Day in
            let date = calendar.date(byAdding: .day, value: i, to: startOfDay)!
            return Day(
                date: date, min: d.0, max: d.1, condition: d.2, precipitationProbability: d.3,
                sunrise: date.addingTimeInterval(6 * 3600 + 38 * 60),
                sunset: date.addingTimeInterval(17 * 3600 + 6 * 60)
            )
        }

        return WeatherSnapshot(
            location: SavedLocation(
                name: "Lisbon",
                coordinate: Coordinate(latitude: 38.72, longitude: -9.14),
                timeZoneID: TimeZone.current.identifier
            ),
            fetchedAt: now,
            utcOffsetSeconds: TimeZone.current.secondsFromGMT(for: now),
            current: Current(
                temperature: 13, apparentTemperature: 12, humidity: 90,
                uvIndex: 2, windSpeed: 9, windDirection: 315, condition: .cloudy
            ),
            hourly: hourly,
            daily: daily
        )
    }
}
