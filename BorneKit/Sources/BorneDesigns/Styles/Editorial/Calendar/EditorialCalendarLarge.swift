import BorneCore
import SwiftUI
import WidgetKit

/// The month in a grid with today ringed in gold; today's events below.
struct EditorialCalendarLarge: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: CalendarEntry

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let cal = entry.calendar
        let rows = CalendarLayout.monthGrid(for: entry.date, calendar: cal).count
        VStack(alignment: .leading, spacing: 6) {
            CalendarHeader(entry: entry)
            Hairline()
            MonthGrid(date: entry.date, calendar: cal,
                      eventDays: CalendarLayout.daysWithEvents(entry.events, calendar: cal),
                      numeralSize: entry.showsEvents ? 13 : 16,
                      rowHeight: entry.showsEvents ? (rows > 5 ? 25 : 29) : (rows > 5 ? 38 : 45))
            if entry.showsEvents {
                SectionRule(title: "today")
                let today = CalendarLayout.agenda(entry.events, from: entry.date, days: 1, calendar: cal).first?.events ?? []
                EventList(events: today, limit: rows > 5 ? 2 : 3, calendar: cal, uses24Hour: entry.uses24Hour,
                          titleSize: 14, spacing: 6, emptyText: "nothing scheduled today")
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(palette.primary)
    }
}

/// "November 2026" in italics with today's weekday and day on the right.
struct CalendarHeader: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: CalendarEntry
    var trailing: AnyView? = nil

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(entry.date.formatted(.dateTime.month(.wide)))
                .font(EditorialTheme.italic(24))
                .foregroundStyle(palette.primary)
            EditorialCaption(entry.date.formatted(.dateTime.year()), size: 9)
            Spacer(minLength: 4)
            if let trailing { trailing }
            EditorialCaption(entry.date.formatted(.dateTime.weekday(.abbreviated)), size: 9, color: palette.golden)
            Text("\(entry.calendar.component(.day, from: entry.date))")
                .font(EditorialTheme.numeral(24, weight: .semibold))
                .foregroundStyle(palette.golden)
                .widgetAccentable()
        }
    }
}
