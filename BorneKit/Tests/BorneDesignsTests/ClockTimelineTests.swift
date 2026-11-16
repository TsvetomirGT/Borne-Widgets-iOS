import BorneCore
import Foundation
import Testing
@testable import BorneDesigns

@Test func clockTimelineHasOneEntryPerMinuteFromMinuteStart() {
    let now = ISO8601DateFormatter().date(from: "2026-11-16T10:15:42Z")!
    let entries = ClockEntry.timeline(from: now, count: 60, uses24Hour: false, worldClocks: [])
    #expect(entries.count == 60)
    #expect(entries.first?.date == ISO8601DateFormatter().date(from: "2026-11-16T10:15:00Z"))
    #expect(entries.last?.date == ISO8601DateFormatter().date(from: "2026-11-16T11:14:00Z"))
    #expect(entries.allSatisfy { !$0.uses24Hour })
}
