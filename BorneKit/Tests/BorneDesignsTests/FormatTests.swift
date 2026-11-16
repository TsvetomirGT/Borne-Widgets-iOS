import Foundation
import Testing
@testable import BorneDesigns

private let utc = TimeZone(identifier: "UTC")!
private func d(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }

@Test func clockPartsTwelveHourHasMeridiem() {
    let p = EditorialFormat.clockParts(d("2026-11-16T14:05:00Z"), utc, uses24Hour: false)
    #expect(p.time == "2:05" && p.meridiem == "PM")
}

@Test func clockPartsTwentyFourHourHasNoMeridiem() {
    let p = EditorialFormat.clockParts(d("2026-11-16T14:05:00Z"), utc, uses24Hour: true)
    #expect(p.time == "14:05" && p.meridiem == nil)
}

@Test func staleLabelSameDayShowsTimeOnly() {
    #expect(EditorialFormat.staleLabel(fetchedAt: d("2026-11-16T09:30:00Z"), now: d("2026-11-16T12:00:00Z"),
                                       zone: utc, uses24Hour: true) == "updated 09:30")
}

@Test func staleLabelOtherDayShowsDay() {
    #expect(EditorialFormat.staleLabel(fetchedAt: d("2026-11-14T09:30:00Z"), now: d("2026-11-16T12:00:00Z"),
                                       zone: utc, uses24Hour: true) == "updated sat 09:30")
}
