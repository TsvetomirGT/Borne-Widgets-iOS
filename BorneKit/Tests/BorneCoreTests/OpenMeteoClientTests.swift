import Foundation
import Testing
@testable import BorneCore

@Test func decodesForecastInLocationTimeZone() throws {
    let s = try OpenMeteoClient.decodeForecast(fixture("forecast"), location: tokyo, fetchedAt: .now)
    #expect(s.current.temperature == 13.2)
    #expect(s.current.condition == .cloudy)
    #expect(s.current.humidity == 90)
    #expect(s.utcOffsetSeconds == 32400)
    #expect(s.hourly.count == 3)
    #expect(s.hourly.first?.time == iso("2026-11-15T15:00:00Z"))   // 00:00 JST
    #expect(s.hourly[2].condition == .rain)
    #expect(s.hourly[2].precipitationProbability == 55)
    #expect(s.daily.first?.date == iso("2026-11-15T15:00:00Z"))
    #expect(s.daily.first?.sunrise == iso("2026-11-15T21:20:00Z"))
    #expect(s.daily[1].precipitationProbability == 80)
    #expect(s.location == tokyo)
}

@Test func forecastURLHasRequiredParams() throws {
    let url = OpenMeteoClient.forecastURL(for: sofia.coordinate)
    #expect(url.host() == "api.open-meteo.com")
    let q = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
    #expect(q.contains(URLQueryItem(name: "timezone", value: "auto")))
    #expect(q.contains(URLQueryItem(name: "forecast_days", value: "7")))
    #expect(q.first { $0.name == "daily" }?.value?.contains("sunrise") == true)
    #expect(q.first { $0.name == "current" }?.value?.contains("uv_index") == true)
    #expect(q.first { $0.name == "latitude" }?.value == "42.6977")
}

@Test func decodesCities() throws {
    let cities = try OpenMeteoClient.decodeCities(fixture("geocoding"))
    #expect(cities.count == 2)
    #expect(cities.first?.name == "Sofia")
    #expect(cities.first?.timeZoneID == "Europe/Sofia")
    #expect(try OpenMeteoClient.decodeCities(Data("{}".utf8)).isEmpty)
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["LIVE"] == "1"))
func liveForecastDecodes() async throws {
    let s = try await OpenMeteoClient().fetch(for: sofia)
    #expect(s.hourly.count >= 24)
    #expect(s.daily.count == 7)
}
