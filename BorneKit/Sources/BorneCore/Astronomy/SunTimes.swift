import Foundation

public enum SunTimes {
    /// Approximate start of evening golden hour.
    public static func goldenHour(sunset: Date) -> Date {
        sunset.addingTimeInterval(-40 * 60)
    }

    /// How far the sun is across the sky, 0 at sunrise to 1 at sunset;
    /// nil while the sun is down.
    public static func progress(now: Date, sunrise: Date, sunset: Date) -> Double? {
        guard sunset > sunrise, now >= sunrise, now <= sunset else { return nil }
        return now.timeIntervalSince(sunrise) / sunset.timeIntervalSince(sunrise)
    }
}
