import Foundation

/// One fetch of weather for one place, in a display-ready shape.
/// Temperatures are °C, wind is km/h; units are applied at display time.
public struct WeatherSnapshot: Codable, Sendable, Equatable {
    public struct Current: Codable, Sendable, Equatable {
        public var temperature: Double
        public var apparentTemperature: Double
        public var humidity: Int
        public var uvIndex: Double
        public var windSpeed: Double
        public var windDirection: Double
        public var condition: WeatherCondition

        public init(temperature: Double, apparentTemperature: Double, humidity: Int, uvIndex: Double,
                    windSpeed: Double, windDirection: Double, condition: WeatherCondition) {
            self.temperature = temperature
            self.apparentTemperature = apparentTemperature
            self.humidity = humidity
            self.uvIndex = uvIndex
            self.windSpeed = windSpeed
            self.windDirection = windDirection
            self.condition = condition
        }
    }

    public struct Hour: Codable, Sendable, Equatable {
        public var time: Date
        public var temperature: Double
        public var precipitationProbability: Int
        public var precipitation: Double
        public var condition: WeatherCondition

        public init(time: Date, temperature: Double, precipitationProbability: Int,
                    precipitation: Double, condition: WeatherCondition) {
            self.time = time
            self.temperature = temperature
            self.precipitationProbability = precipitationProbability
            self.precipitation = precipitation
            self.condition = condition
        }
    }

    public struct Day: Codable, Sendable, Equatable {
        /// Start of the day in the location's time zone.
        public var date: Date
        public var min: Double
        public var max: Double
        public var condition: WeatherCondition
        public var precipitationProbability: Int
        public var sunrise: Date
        public var sunset: Date

        public init(date: Date, min: Double, max: Double, condition: WeatherCondition,
                    precipitationProbability: Int, sunrise: Date, sunset: Date) {
            self.date = date
            self.min = min
            self.max = max
            self.condition = condition
            self.precipitationProbability = precipitationProbability
            self.sunrise = sunrise
            self.sunset = sunset
        }
    }

    public var location: SavedLocation
    public var fetchedAt: Date
    public var utcOffsetSeconds: Int
    public var current: Current
    public var hourly: [Hour]
    public var daily: [Day]

    public init(location: SavedLocation, fetchedAt: Date, utcOffsetSeconds: Int,
                current: Current, hourly: [Hour], daily: [Day]) {
        self.location = location
        self.fetchedAt = fetchedAt
        self.utcOffsetSeconds = utcOffsetSeconds
        self.current = current
        self.hourly = hourly
        self.daily = daily
    }

    /// The location's time zone at fetch time (fixed offset).
    public var timeZone: TimeZone { TimeZone(secondsFromGMT: utcOffsetSeconds) ?? .gmt }

    /// Temperature and condition to show as "now". After an hour the
    /// fetched `current` block is out of date, so use the forecast for the
    /// hour containing `now` instead.
    public func currentConditions(at now: Date) -> (temperature: Double, condition: WeatherCondition) {
        if now.timeIntervalSince(fetchedAt) > 3600, let hour = hours(from: now, count: 1).first {
            return (hour.temperature, hour.condition)
        }
        return (current.temperature, current.condition)
    }

    /// Up to `count` hours, starting with the hour that contains `now`.
    public func hours(from now: Date, count: Int) -> [Hour] {
        guard let start = hourly.firstIndex(where: { $0.time.addingTimeInterval(3600) > now }) else { return [] }
        return Array(hourly[start...].prefix(count))
    }

    /// The day containing `now`, if the forecast covers it.
    public func today(at now: Date) -> Day? {
        daily.last(where: { $0.date <= now && $0.date.addingTimeInterval(86_400) > now })
    }

    /// Up to `count` days that start after the day containing `now`.
    public func days(after now: Date, count: Int) -> [Day] {
        Array(daily.filter { $0.date > now }.prefix(count))
    }
}
