import Foundation

public protocol WeatherFetching: Sendable {
    func fetch(for location: SavedLocation) async throws -> WeatherSnapshot
}

/// Client for the free Open-Meteo forecast and geocoding APIs (no key needed).
/// Weather data by Open-Meteo.com, CC BY 4.0.
public struct OpenMeteoClient: WeatherFetching {
    public enum ClientError: Error { case badStatus(Int), malformed(String) }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(for location: SavedLocation) async throws -> WeatherSnapshot {
        let data = try await get(Self.forecastURL(for: location.coordinate))
        return try Self.decodeForecast(data, location: location, fetchedAt: .now)
    }

    public func searchCities(_ query: String) async throws -> [SavedLocation] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        return try Self.decodeCities(try await get(Self.geocodingURL(for: trimmed)))
    }

    private func get(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ClientError.badStatus(http.statusCode)
        }
        return data
    }

    // MARK: URLs

    static func forecastURL(for coordinate: Coordinate) -> URL {
        var c = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        c.queryItems = [
            .init(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
            .init(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
            .init(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,uv_index,wind_speed_10m,wind_direction_10m"),
            .init(name: "hourly", value: "temperature_2m,precipitation_probability,precipitation,weather_code"),
            .init(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "7"),
        ]
        return c.url!
    }

    static func geocodingURL(for query: String) -> URL {
        var c = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        c.queryItems = [
            .init(name: "name", value: query),
            .init(name: "count", value: "10"),
            .init(name: "language", value: "en"),
            .init(name: "format", value: "json"),
        ]
        return c.url!
    }

    // MARK: Decoding

    static func decodeForecast(_ data: Data, location: SavedLocation, fetchedAt: Date) throws -> WeatherSnapshot {
        let dto = try JSONDecoder().decode(ForecastDTO.self, from: data)
        let zone = TimeZone(secondsFromGMT: dto.utc_offset_seconds) ?? .gmt
        let dateTime = formatter("yyyy-MM-dd'T'HH:mm", zone)
        let dateOnly = formatter("yyyy-MM-dd", zone)

        func parse(_ s: String, _ f: DateFormatter) throws -> Date {
            guard let d = f.date(from: s) else { throw ClientError.malformed(s) }
            return d
        }

        let h = dto.hourly
        let hourly = try h.time.indices.map { i in
            WeatherSnapshot.Hour(
                time: try parse(h.time[i], dateTime),
                temperature: h.temperature_2m[i] ?? 0,
                precipitationProbability: h.precipitation_probability[i] ?? 0,
                precipitation: h.precipitation[i] ?? 0,
                condition: WeatherCondition(wmoCode: h.weather_code[i] ?? 3)
            )
        }

        let d = dto.daily
        let daily = try d.time.indices.map { i in
            WeatherSnapshot.Day(
                date: try parse(d.time[i], dateOnly),
                min: d.temperature_2m_min[i] ?? 0,
                max: d.temperature_2m_max[i] ?? 0,
                condition: WeatherCondition(wmoCode: d.weather_code[i] ?? 3),
                precipitationProbability: d.precipitation_probability_max[i] ?? 0,
                sunrise: try parse(d.sunrise[i], dateTime),
                sunset: try parse(d.sunset[i], dateTime)
            )
        }

        let c = dto.current
        return WeatherSnapshot(
            location: location,
            fetchedAt: fetchedAt,
            utcOffsetSeconds: dto.utc_offset_seconds,
            current: .init(
                temperature: c.temperature_2m,
                apparentTemperature: c.apparent_temperature,
                humidity: c.relative_humidity_2m,
                uvIndex: c.uv_index ?? 0,
                windSpeed: c.wind_speed_10m,
                windDirection: c.wind_direction_10m,
                condition: WeatherCondition(wmoCode: c.weather_code)
            ),
            hourly: hourly,
            daily: daily
        )
    }

    static func decodeCities(_ data: Data) throws -> [SavedLocation] {
        let dto = try JSONDecoder().decode(GeocodingDTO.self, from: data)
        return (dto.results ?? []).map { r in
            SavedLocation(
                name: r.name,
                coordinate: Coordinate(latitude: r.latitude, longitude: r.longitude),
                timeZoneID: r.timezone ?? TimeZone.current.identifier,
                region: [r.admin1, r.country].compactMap { $0 }.joined(separator: ", ")
            )
        }
    }

    private static func formatter(_ format: String, _ zone: TimeZone) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = zone
        f.dateFormat = format
        return f
    }
}

// MARK: - Wire format

// Field names mirror the API so the DTOs stay greppable against its docs.
private struct ForecastDTO: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let apparent_temperature: Double
        let relative_humidity_2m: Int
        let weather_code: Int
        let uv_index: Double?
        let wind_speed_10m: Double
        let wind_direction_10m: Double
    }
    struct Hourly: Decodable {
        let time: [String]
        let temperature_2m: [Double?]
        let precipitation_probability: [Int?]
        let precipitation: [Double?]
        let weather_code: [Int?]
    }
    struct Daily: Decodable {
        let time: [String]
        let weather_code: [Int?]
        let temperature_2m_max: [Double?]
        let temperature_2m_min: [Double?]
        let precipitation_probability_max: [Int?]
        let sunrise: [String]
        let sunset: [String]
    }
    let utc_offset_seconds: Int
    let current: Current
    let hourly: Hourly
    let daily: Daily
}

private struct GeocodingDTO: Decodable {
    struct Result: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let admin1: String?
        let timezone: String?
    }
    let results: [Result]?
}
