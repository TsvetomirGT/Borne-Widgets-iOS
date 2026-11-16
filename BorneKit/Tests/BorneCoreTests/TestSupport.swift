import Foundation
@testable import BorneCore

func iso(_ string: String) -> Date {
    ISO8601DateFormatter().date(from: string)!
}

func fixture(_ name: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
    return try! Data(contentsOf: url)
}

let sofia = SavedLocation(
    name: "Sofia",
    coordinate: Coordinate(latitude: 42.6977, longitude: 23.3219),
    timeZoneID: "Europe/Sofia"
)

let tokyo = SavedLocation(
    name: "Tokyo",
    coordinate: Coordinate(latitude: 35.6895, longitude: 139.6917),
    timeZoneID: "Asia/Tokyo"
)

extension WeatherSnapshot {
    /// Builds a snapshot with `count` hourly entries starting at `hourlyStart`
    /// and `dayCount` daily entries starting at the day of `hourlyStart`.
    static func make(
        location: SavedLocation = sofia,
        hourlyStart: Date,
        count: Int = 48,
        hour: (Int) -> (temp: Double, precip: Int, condition: WeatherCondition) = { _ in (10, 0, .cloudy) },
        days: [(min: Double, max: Double, precip: Int, condition: WeatherCondition)] = [(5, 12, 0, .cloudy), (6, 13, 0, .cloudy)],
        utcOffsetSeconds: Int = 0
    ) -> WeatherSnapshot {
        let hours = (0..<count).map { i in
            let h = hour(i)
            return Hour(
                time: hourlyStart.addingTimeInterval(Double(i) * 3600),
                temperature: h.temp,
                precipitationProbability: h.precip,
                precipitation: h.precip >= 50 ? 1.2 : 0,
                condition: h.condition
            )
        }
        let dayList = days.enumerated().map { i, d in
            let date = hourlyStart.addingTimeInterval(Double(i) * 86_400)
            return Day(
                date: date,
                min: d.min, max: d.max,
                condition: d.condition,
                precipitationProbability: d.precip,
                sunrise: date.addingTimeInterval(6.5 * 3600),
                sunset: date.addingTimeInterval(17 * 3600)
            )
        }
        return WeatherSnapshot(
            location: location,
            fetchedAt: hourlyStart,
            utcOffsetSeconds: utcOffsetSeconds,
            current: Current(
                temperature: 10, apparentTemperature: 9, humidity: 80,
                uvIndex: 1, windSpeed: 9, windDirection: 315, condition: .cloudy
            ),
            hourly: hours,
            daily: dayList
        )
    }
}
