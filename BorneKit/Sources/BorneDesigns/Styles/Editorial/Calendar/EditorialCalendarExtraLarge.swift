import BorneCore
import SwiftUI
import WidgetKit

/// The full-page calendar (iOS 27): the month, then the next seven days as
/// an agenda, with the moon's phase as a small almanac detail.
struct EditorialCalendarExtraLarge: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: CalendarEntry

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let cal = entry.calendar
        let rows = CalendarLayout.monthGrid(for: entry.date, calendar: cal).count
        let phase = MoonPhase(date: entry.date)
        VStack(alignment: .leading, spacing: 6) {
            CalendarHeader(entry: entry)
            HStack(spacing: 6) {
                MoonGlyph(phase: phase).frame(width: 12, height: 12)
                EditorialCaption(phase.name.rawValue, size: 8)
                Spacer()
                EditorialCaption("week \(cal.component(.weekOfYear, from: entry.date))", size: 8)
            }
            Hairline()
            MonthGrid(date: entry.date, calendar: cal,
                      eventDays: CalendarLayout.daysWithEvents(entry.events, calendar: cal),
                      numeralSize: entry.showsEvents ? 14 : 18,
                      rowHeight: entry.showsEvents ? (rows > 5 ? 26 : 30) : (rows > 5 ? 56 : 66))
            if entry.showsEvents {
                SectionRule(title: "next 7 days")
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(CalendarLayout.agenda(entry.events, from: entry.date, days: 7, calendar: cal), id: \.day) { group in
                        AgendaDay(day: group.day, events: group.events, entry: entry)
                    }
                }
            } else {
                Spacer(minLength: 0)
                Hairline()
                Text("Allow Calendar access in Borne to see your events here.")
                    .font(EditorialTheme.italic(14))
                    .foregroundStyle(palette.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

/// One agenda line: "TUE 17" on the left, up to two events on the right.
private struct AgendaDay: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let day: Date
    let events: [CalendarEvent]
    let entry: CalendarEntry

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let cal = entry.calendar
        let isToday = day == cal.startOfDay(for: entry.date)
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                EditorialCaption(EditorialFormat.weekdayShort(day, cal.timeZone), size: 8,
                                 color: isToday ? palette.golden : nil)
                Text("\(cal.component(.day, from: day))")
                    .font(EditorialTheme.numeral(13, weight: .semibold))
                    .foregroundStyle(isToday ? palette.golden : palette.primary)
                    .monospacedDigit()
            }
            .frame(width: 52, alignment: .leading)
            EventList(events: events, limit: 2, calendar: cal, uses24Hour: entry.uses24Hour,
                      titleSize: 13, spacing: 3, emptyText: "—")
        }
    }
}
