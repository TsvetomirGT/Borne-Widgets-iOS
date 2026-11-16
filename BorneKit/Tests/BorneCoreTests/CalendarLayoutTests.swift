import Foundation
import Testing
@testable import BorneCore

private func cal(firstWeekday: Int) -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    c.firstWeekday = firstWeekday
    return c
}
private func d(_ s: String) -> Date { ISO8601DateFormatter().date(from: s.count == 10 ? s + "T00:00:00Z" : s)! }
private func ev(_ id: String, _ start: String, _ end: String, allDay: Bool = false) -> CalendarEvent {
    CalendarEvent(id: id, title: id, start: d(start), end: d(end), isAllDay: allDay, color: RGB(red: 0.2, green: 0.4, blue: 0.8))
}

@Test func monthGridMondayStart() {
    let g = CalendarLayout.monthGrid(for: d("2026-11-16"), calendar: cal(firstWeekday: 2))
    #expect(g.count == 6)
    #expect(g[0] == [nil, nil, nil, nil, nil, nil, d("2026-11-01")])
    #expect(g.allSatisfy { $0.count == 7 })
    #expect(g.flatMap { $0 }.compactMap { $0 }.count == 30)
}

@Test func monthGridSundayStart() {
    let g = CalendarLayout.monthGrid(for: d("2026-11-16"), calendar: cal(firstWeekday: 1))
    #expect(g.count == 5)
    #expect(g[0][0] == d("2026-11-01"))
}

@Test func monthGridSixRows() {
    #expect(CalendarLayout.monthGrid(for: d("2026-03-10"), calendar: cal(firstWeekday: 2)).count == 6)
}

@Test func weekContainingMondayStart() {
    let w = CalendarLayout.week(containing: d("2026-11-18T15:00:00Z"), calendar: cal(firstWeekday: 2))
    #expect(w.first == d("2026-11-16"))
    #expect(w.last == d("2026-11-22"))
    #expect(w.count == 7)
}

@Test func agendaMultiDayEventOnEachDay() {
    let trip = ev("trip", "2026-11-17T09:00:00Z", "2026-11-19T18:00:00Z")
    let a = CalendarLayout.agenda([trip], from: d("2026-11-16T10:00:00Z"), days: 7, calendar: cal(firstWeekday: 2))
    #expect(a.filter { $0.events.contains(trip) }.map(\.day) == [d("2026-11-17"), d("2026-11-18"), d("2026-11-19")])
}

@Test func agendaAllDayEndingAtMidnightDoesNotSpill() {
    let holiday = ev("holiday", "2026-11-17", "2026-11-18", allDay: true)
    let a = CalendarLayout.agenda([holiday], from: d("2026-11-16"), days: 7, calendar: cal(firstWeekday: 2))
    #expect(a.filter { $0.events.contains(holiday) }.map(\.day) == [d("2026-11-17")])
}

@Test func agendaAllDayFirst() {
    let early = ev("early", "2026-11-17T08:00:00Z", "2026-11-17T09:00:00Z")
    let allDay = ev("allday", "2026-11-17", "2026-11-18", allDay: true)
    let a = CalendarLayout.agenda([early, allDay], from: d("2026-11-16"), days: 7, calendar: cal(firstWeekday: 2))
    #expect(a[1].events.map(\.id) == ["allday", "early"])
}

@Test func agendaIncludesEmptyDays() {
    let a = CalendarLayout.agenda([], from: d("2026-11-16T13:00:00Z"), days: 7, calendar: cal(firstWeekday: 2))
    #expect(a.count == 7)
    #expect(a[0].day == d("2026-11-16"))
}

@Test func upcomingSkipsEnded() {
    let past = ev("past", "2026-11-16T08:00:00Z", "2026-11-16T09:00:00Z")
    let now = ev("now", "2026-11-16T12:30:00Z", "2026-11-16T14:00:00Z")
    let later = ev("later", "2026-11-16T16:00:00Z", "2026-11-16T17:00:00Z")
    let u = CalendarLayout.upcoming([later, past, now], after: d("2026-11-16T13:00:00Z"), limit: 5)
    #expect(u.map(\.id) == ["now", "later"])
}

@Test func daysWithEventsCoverMultiDay() {
    let trip = ev("trip", "2026-11-17T09:00:00Z", "2026-11-19T18:00:00Z")
    #expect(CalendarLayout.daysWithEvents([trip], calendar: cal(firstWeekday: 2))
            == [d("2026-11-17"), d("2026-11-18"), d("2026-11-19")])
}

@Test func reloadDatesIncludeNextMidnight() {
    let now = d("2026-11-16T13:20:00Z")
    let soon = ev("soon", "2026-11-16T15:00:00Z", "2026-11-16T16:00:00Z")
    let far = ev("far", "2026-11-18T15:00:00Z", "2026-11-18T16:00:00Z")
    let r = CalendarLayout.reloadDates(events: [soon, far], now: now, calendar: cal(firstWeekday: 2))
    #expect(r == [now, d("2026-11-16T15:00:00Z"), d("2026-11-16T16:00:00Z"), d("2026-11-17")])
}

@Test func samplesIncludeAllDayAndMultiDay() {
    let s = CalendarEvent.samples(around: d("2026-11-16T13:00:00Z"), calendar: cal(firstWeekday: 2))
    #expect(s.count >= 6)
    #expect(s.contains { $0.isAllDay })
    #expect(s.contains { cal(firstWeekday: 2).dateComponents([.day], from: $0.start, to: $0.end).day! >= 2 })
}
