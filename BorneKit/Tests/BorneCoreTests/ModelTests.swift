import Foundation
import Testing
@testable import BorneCore

private let midnight = iso("2026-11-16T00:00:00Z")

@Test func wmoMapping() {
    #expect(WeatherCondition(wmoCode: 3) == .cloudy)
    #expect(WeatherCondition(wmoCode: 3).text == "Cloudy")
    #expect(WeatherCondition(wmoCode: 65) == .heavyRain)
    #expect(WeatherCondition(wmoCode: 999) == .cloudy)
    #expect(WeatherCondition(wmoCode: 75).isSnow)
    #expect(!WeatherCondition(wmoCode: 61).isSnow)
    #expect(WeatherCondition(wmoCode: 0).symbolName == "sun.max")
}

@Test func temperatureFormatting() {
    #expect(TemperatureUnit.celsius.format(13.4) == "13°")
    #expect(TemperatureUnit.celsius.format(-0.4) == "0°")
    #expect(TemperatureUnit.celsius.format(-3.6) == "-4°")
    #expect(TemperatureUnit.fahrenheit.format(13) == "55°")
}

@Test func windFormatting() {
    #expect(WindUnit.kmh.format(12.4) == "12 km/h")
    #expect(WindUnit.mph.format(16.1) == "10 mph")
    #expect(WindUnit.ms.format(36) == "10 m/s")
}

@Test func compass() {
    #expect(WindUnit.compass(315) == "NW")
    #expect(WindUnit.compass(350) == "N")
    #expect(WindUnit.compass(90) == "E")
}

@Test func hoursStartAtCurrentHour() {
    let s = WeatherSnapshot.make(hourlyStart: midnight, count: 48)
    let h = s.hours(from: midnight.addingTimeInterval(5 * 3600 + 20 * 60), count: 18)
    #expect(h.count == 18)
    #expect(h.first?.time == midnight.addingTimeInterval(5 * 3600))
}

@Test func hoursTruncateAtEndOfData() {
    let s = WeatherSnapshot.make(hourlyStart: midnight, count: 10)
    #expect(s.hours(from: midnight.addingTimeInterval(5 * 3600), count: 18).count == 5)
}

@Test func todayAndFollowingDays() {
    let s = WeatherSnapshot.make(hourlyStart: midnight, days: [(1, 10, 0, .clear), (2, 11, 0, .clear), (3, 12, 0, .clear)])
    let now = midnight.addingTimeInterval(9 * 3600)
    #expect(s.today(at: now)?.max == 10)
    #expect(s.days(after: now, count: 5).map(\.max) == [11, 12])
}

@Test func coordinateNear() {
    #expect(Coordinate(latitude: 42.70, longitude: 23.32).isNear(.init(latitude: 42.705, longitude: 23.321)))
    #expect(!Coordinate(latitude: 42.70, longitude: 23.32).isNear(.init(latitude: 42.75, longitude: 23.32)))
}

@Test func sampleIsUsable() {
    let s = WeatherSnapshot.sample
    #expect(s.location.name == "Lisbon")
    #expect(s.hourly.count >= 24)
    #expect(s.daily.count == 7)
    #expect(s.hours(from: .now, count: 18).count == 18)
}

@Test func sampleHourlyAgreesWithCurrentTemperature() {
    let s = WeatherSnapshot.sample
    let first = s.hours(from: .now, count: 1).first!
    #expect(abs(first.temperature - s.current.temperature) < 0.5)
}
