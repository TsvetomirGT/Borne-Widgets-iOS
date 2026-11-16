import BorneCore
import Foundation
import SwiftUI
import Testing
@testable import BorneDesigns

private let march = ISO8601DateFormatter().date(from: "2026-03-10T10:00:00Z")!

private func mondayCalendar() -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.firstWeekday = 2
    return c
}

@Test func visibleTruncatesWithMore() {
    let events = CalendarEvent.samples(around: march, calendar: mondayCalendar())
    let v = EventRow.visible(Array(events.prefix(5)), limit: 3)
    #expect(v.shown.count == 3)
    #expect(v.more == 2)
    #expect(EventRow.visible(Array(events.prefix(2)), limit: 3).more == 0)
}

@Test func noAccessEntryHasNoEvents() {
    let e = CalendarEntry.noAccess(at: march)
    #expect(e.access == .denied)
    #expect(e.events.isEmpty)
    #expect(CalendarEntry.sample.access == .granted)
    #expect(!CalendarEntry.sample.events.isEmpty)
}

/// A 6-row month (March 2026, Monday start) must still fit the real
/// iPhone 18 Pro sizes, with and without events.
@MainActor
@Test(arguments: [
    (WidgetSize.large, CGSize(width: 349.67, height: 365), true),
    (WidgetSize.large, CGSize(width: 349.67, height: 365), false),
    (WidgetSize.extraLarge, CGSize(width: 349.67, height: 565.67), true),
    (WidgetSize.extraLarge, CGSize(width: 349.67, height: 565.67), false),
])
func calendarFitsOnIPhone18Pro(size: WidgetSize, device: CGSize, withEvents: Bool) {
    let cal = mondayCalendar()
    let entry = withEvents
        ? CalendarEntry(date: march, access: .granted, events: CalendarEvent.samples(around: march, calendar: cal), calendar: cal)
        : CalendarEntry(date: march, access: .denied, events: [], calendar: cal)
    let card = DesignCard(design: DesignCatalog.editorialCalendar, size: size)
    let content = DesignRegistry.view(for: card, weather: .sample, clock: .sample, calendar: entry)
    let r = ImageRenderer(content: content.fixedSize(horizontal: false, vertical: true).frame(width: device.width))
    let height = CGFloat(r.cgImage?.height ?? 0) / r.scale
    #expect(height <= device.height + 0.5, "\(card.id) needs \(height)pt, device has \(device.height)")
}

@Test func whenLabelSaysTimeOrWeekday() {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    let now = ISO8601DateFormatter().date(from: "2026-11-16T13:00:00Z")!
    func e(_ s: String, allDay: Bool = false) -> CalendarEvent {
        let start = ISO8601DateFormatter().date(from: s)!
        return CalendarEvent(id: s, title: "x", start: start, end: start.addingTimeInterval(allDay ? 86400 : 3600),
                             isAllDay: allDay, color: RGB(red: 0, green: 0, blue: 0))
    }
    #expect(EditorialCalendarSmall.whenLabel(e("2026-11-16T15:00:00Z"), now: now, calendar: cal, uses24Hour: true) == "15:00")
    #expect(EditorialCalendarSmall.whenLabel(e("2026-11-17T09:30:00Z"), now: now, calendar: cal, uses24Hour: true) == "tue 09:30")
    #expect(EditorialCalendarSmall.whenLabel(e("2026-11-18T00:00:00Z", allDay: true), now: now, calendar: cal, uses24Hour: true) == "wed")
    #expect(EditorialCalendarSmall.whenLabel(e("2026-11-16T12:30:00Z"), now: now, calendar: cal, uses24Hour: true) == "now · until 13:30")
}
