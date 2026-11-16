import Foundation
import Testing
@testable import BorneCore

private let midnight = iso("2026-11-16T00:00:00Z")
private func at(_ hhmm: String) -> Date { iso("2026-11-16T\(hhmm):00Z") }

private func snapshot(
    rainAt: Set<Int> = [], precip: Int = 60, condition: WeatherCondition = .rain,
    tomorrow: (max: Double, precip: Int, condition: WeatherCondition)? = (12, 0, .cloudy)
) -> WeatherSnapshot {
    var days: [(min: Double, max: Double, precip: Int, condition: WeatherCondition)] = [(5, 12, 0, .cloudy)]
    if let tomorrow { days.append((6, tomorrow.max, tomorrow.precip, tomorrow.condition)) }
    return .make(
        hourlyStart: midnight,
        hour: { i in rainAt.contains(i) ? (10, precip, condition) : (10, 0, .cloudy) },
        days: days
    )
}

private func sentence(_ s: WeatherSnapshot, _ now: String = "09:10") -> String {
    WeatherSummary.sentence(for: s, now: at(now), unit: .celsius)
}

@Test func referenceSentence() {
    #expect(sentence(snapshot(tomorrow: (15, 80, .rain))) == "No rain in the next 18 hours. Tomorrow 15°, rain likely.")
}

@Test func rainFromHour() {
    #expect(sentence(snapshot(rainAt: [15, 16])).hasPrefix("Rain likely from 15:00."))
}

@Test func rainNow() {
    #expect(sentence(snapshot(rainAt: [9])).hasPrefix("Rain likely now."))
}

@Test func snowWording() {
    #expect(sentence(snapshot(rainAt: [15], condition: .snow)).hasPrefix("Snow likely from 15:00."))
}

@Test func chanceOfRain() {
    #expect(sentence(snapshot(rainAt: [12], precip: 40)).hasPrefix("Chance of rain later."))
}

@Test func rainBeyond18HoursIsIgnored() {
    // 09:00 + 18h window ends before 03:00 next day (hour index 27).
    #expect(sentence(snapshot(rainAt: [28])).hasPrefix("No rain in the next 18 hours."))
}

@Test func warmer() {
    #expect(sentence(snapshot(tomorrow: (18, 10, .clear))).hasSuffix("Tomorrow 18°, warmer."))
}

@Test func cooler() {
    #expect(sentence(snapshot(tomorrow: (8, 10, .clear))).hasSuffix("Tomorrow 8°, cooler."))
}

@Test func similar() {
    #expect(sentence(snapshot(tomorrow: (13, 10, .clear))).hasSuffix("Tomorrow 13°."))
}

@Test func snowTomorrow() {
    #expect(sentence(snapshot(tomorrow: (2, 70, .snow))).hasSuffix("Tomorrow 2°, snow likely."))
}

@Test func noTomorrowData() {
    #expect(sentence(snapshot(tomorrow: nil)) == "No rain in the next 18 hours.")
}

@Test func usesLocationTimeZoneForTimes() {
    var s = snapshot(rainAt: [15])
    s.utcOffsetSeconds = 9 * 3600   // 15:00Z is 00:00 in UTC+9
    #expect(sentence(s).hasPrefix("Rain likely from 00:00."))
}
