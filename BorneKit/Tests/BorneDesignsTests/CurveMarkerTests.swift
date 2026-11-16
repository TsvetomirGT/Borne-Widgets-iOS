import BorneCore
import Foundation
import Testing
@testable import BorneDesigns

private let t0 = ISO8601DateFormatter().date(from: "2026-11-16T11:00:00Z")!

private func hours(_ temps: [Double]) -> [WeatherSnapshot.Hour] {
    temps.enumerated().map { i, t in
        .init(time: t0.addingTimeInterval(Double(i) * 3600), temperature: t,
              precipitationProbability: 0, precipitation: 0, condition: .cloudy)
    }
}

@Test func nowPositionIsFractionalHourIndex() {
    let h = hours([9, 10, 11])
    #expect(abs(TemperatureCurve.nowPosition(in: h, now: t0.addingTimeInterval(16 * 60))! - 16.0 / 60) < 1e-9)
    #expect(TemperatureCurve.nowPosition(in: h, now: t0.addingTimeInterval(-3600)) == nil)
}

@Test func everyHourGetsATemperatureWhenThereIsRoom() {
    // 7 points across ~322pt (large widget), now at 13:42 → hour 0 is 13:00.
    #expect(TemperatureCurve.valueLabelIndices(hourCount: 7, width: 322, nowPosition: 0.7) == [2, 3, 4, 5, 6])
}

@Test func hourNextToNowIsSkipped() {
    // Hour 1 (14:00) is ~16pt from the Now dot on a 322pt plot: its label would overlap.
    #expect(!TemperatureCurve.valueLabelIndices(hourCount: 7, width: 322, nowPosition: 0.7).contains(1))
    // With now right on the hour, the next hour is a full step away and keeps its label.
    #expect(TemperatureCurve.valueLabelIndices(hourCount: 7, width: 322, nowPosition: 0).contains(1))
}

@Test func narrowPlotsLabelEveryOtherHour() {
    #expect(TemperatureCurve.valueLabelIndices(hourCount: 25, width: 322, nowPosition: nil) == Array(stride(from: 0, to: 25, by: 2)))
}

@Test func mediumShowsTodaysHighAndLow() {
    #expect(EditorialWeatherMedium.statTitles == ["feels", "rain", "hi/lo"])
}
