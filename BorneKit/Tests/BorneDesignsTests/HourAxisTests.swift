import Foundation
import Testing
@testable import BorneDesigns

private let utc = TimeZone(identifier: "UTC")!
private func d(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }

@Test func labelEveryHourWhenThereIsRoom() {
    // Full-page widget: 24 hours across ~322pt.
    #expect(TemperatureCurve.labelStride(hourCount: 24, width: 322) == 1)
    // Large widget: 18 hours across ~322pt.
    #expect(TemperatureCurve.labelStride(hourCount: 18, width: 322) == 1)
}

@Test func labelEveryOtherHourWhenTight() {
    // Medium widget: 18 hours across ~200pt.
    #expect(TemperatureCurve.labelStride(hourCount: 18, width: 200) == 2)
}

@Test func compactHourLabels() {
    #expect(EditorialFormat.compactHour(d("2026-11-16T14:00:00Z"), utc, uses24Hour: true) == "14")
    #expect(EditorialFormat.compactHour(d("2026-11-16T09:00:00Z"), utc, uses24Hour: true) == "09")
    #expect(EditorialFormat.compactHour(d("2026-11-16T14:00:00Z"), utc, uses24Hour: false) == "2p")
    #expect(EditorialFormat.compactHour(d("2026-11-16T00:00:00Z"), utc, uses24Hour: false) == "12a")
}

@Test func curveCoversNowPlusSixHours() {
    #expect(EditorialTheme.curveHours == 6)
    #expect(EditorialTheme.curveTitle == "next 6 hours")
}

@Test func fullTimeLabelsWhenSpacious() {
    // 7 points across a medium widget's ~200pt: ~33pt apart.
    #expect(TemperatureCurve.usesFullTimeLabels(hourCount: 7, width: 200))
    // 24 points across ~322pt: ~14pt apart.
    #expect(!TemperatureCurve.usesFullTimeLabels(hourCount: 24, width: 322))
}
