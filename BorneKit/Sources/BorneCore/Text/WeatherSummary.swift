import Foundation

/// The one-line, human summary shown on the large weather widget,
/// e.g. "No rain in the next 18 hours. Tomorrow 15°, rain likely."
public enum WeatherSummary {
    static let windowHours = 18
    static let likely = 50
    static let chance = 30
    static let notableChange = 3.0

    public static func sentence(for snapshot: WeatherSnapshot, now: Date, unit: TemperatureUnit) -> String {
        [nextHours(snapshot, now: now), tomorrow(snapshot, now: now, unit: unit)]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private static func nextHours(_ s: WeatherSnapshot, now: Date) -> String {
        let hours = s.hours(from: now, count: windowHours)
        if let wet = hours.first(where: { $0.precipitationProbability >= likely }) {
            let word = wet.condition.isSnow ? "Snow" : "Rain"
            if wet.time <= now { return "\(word) likely now." }
            return "\(word) likely from \(clock(wet.time, s.timeZone))."
        }
        if let maybe = hours.max(by: { $0.precipitationProbability < $1.precipitationProbability }),
           maybe.precipitationProbability >= chance {
            return "Chance of \(maybe.condition.isSnow ? "snow" : "rain") later."
        }
        return "No rain in the next \(windowHours) hours."
    }

    private static func tomorrow(_ s: WeatherSnapshot, now: Date, unit: TemperatureUnit) -> String? {
        guard let day = s.days(after: now, count: 1).first else { return nil }
        let base = "Tomorrow \(unit.format(day.max))"
        if day.precipitationProbability >= likely {
            return base + (day.condition.isSnow ? ", snow likely." : ", rain likely.")
        }
        if let today = s.today(at: now) {
            if day.max - today.max >= notableChange { return base + ", warmer." }
            if today.max - day.max >= notableChange { return base + ", cooler." }
        }
        return base + "."
    }

    private static func clock(_ date: Date, _ zone: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = zone
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
