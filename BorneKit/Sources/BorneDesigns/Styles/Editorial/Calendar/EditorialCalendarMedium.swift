import BorneCore
import SwiftUI
import WidgetKit

/// The date on the left; this week and what's next on the right.
struct EditorialCalendarMedium: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: CalendarEntry

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let cal = entry.calendar
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                EditorialCaption(entry.date.formatted(.dateTime.weekday(.wide)), size: 9, color: palette.golden)
                Text("\(cal.component(.day, from: entry.date))")
                    .font(EditorialTheme.numeral(52, weight: .semibold))
                    .foregroundStyle(palette.primary)
                    .monospacedDigit()
                    .widgetAccentable()
                Text(entry.date.formatted(.dateTime.month(.wide)))
                    .font(EditorialTheme.italic(17))
                    .foregroundStyle(palette.primary)
                Spacer(minLength: 2)
                EditorialCaption("week \(cal.component(.weekOfYear, from: entry.date))", size: 8)
            }
            .frame(width: 96, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                WeekStrip(date: entry.date, calendar: cal,
                          eventDays: CalendarLayout.daysWithEvents(entry.events, calendar: cal),
                          numeralSize: entry.showsEvents ? 14 : 18)
                if entry.showsEvents {
                    Hairline()
                    let next = CalendarLayout.upcoming(entry.events, after: entry.date, limit: 3)
                    if next.isEmpty { EditorialCaption("nothing coming up", size: 8) }
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(next) { e in
                            EventRow(event: e, calendar: cal, uses24Hour: entry.uses24Hour, titleSize: 13, timeWidth: 60,
                                     label: EditorialCalendarSmall.whenLabel(e, now: entry.date, calendar: cal,
                                                                             uses24Hour: entry.uses24Hour))
                        }
                    }
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                    Hairline()
                    EditorialCaption(entry.date.formatted(.dateTime.month(.wide).year()), size: 8)
                }
            }
        }
    }
}
