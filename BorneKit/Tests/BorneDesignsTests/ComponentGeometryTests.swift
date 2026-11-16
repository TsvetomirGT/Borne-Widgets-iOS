import BorneCore
import Foundation
import Testing
@testable import BorneDesigns

private func hour(_ precip: Int) -> WeatherSnapshot.Hour {
    .init(time: .now, temperature: 10, precipitationProbability: precip, precipitation: 0, condition: .rain)
}

@Test func rainRunsGroupConsecutiveWetHours() {
    let hours = [0, 60, 70, 10, 50, 0, 80].map(hour)
    #expect(TemperatureCurve.rainRuns(hours) == [1...2, 4...4, 6...6])
}

@Test func rainRunsEmptyWhenDry() {
    #expect(TemperatureCurve.rainRuns([0, 49, 10].map(hour)).isEmpty)
}

@Test func curvePointsSpanRectWidth() {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
    let pts = TemperatureCurve.points(for: [10, 12, 14], in: rect)
    #expect(pts.first?.x == 0 && pts.last?.x == 100)
    #expect(pts[2].y < pts[0].y)   // warmer is higher
}

@Test func handAnglesAtThreeThirty() {
    let date = ISO8601DateFormatter().date(from: "2026-11-16T15:30:00Z")!
    let (h, m) = AnalogFace.handAngles(date, TimeZone(identifier: "UTC")!)
    #expect(abs(m - .pi) < 1e-9)
    #expect(abs(h - (3.5 / 12 * 2 * .pi)) < 1e-9)
}

@Test func sunArcEndpoints() {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
    #expect(abs(SunArc.point(in: rect, at: 0).x - 0) < 1e-9)
    #expect(abs(SunArc.point(in: rect, at: 1).x - 100) < 1e-9)
    #expect(abs(SunArc.point(in: rect, at: 0.5).y - 0) < 1e-9)   // zenith at top
}
