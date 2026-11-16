import BorneCore
import SwiftUI
import WidgetKit

/// Today's date set large; the next event beneath it when allowed.
struct EditorialCalendarSmall: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let entry: CalendarEntry

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let cal = entry.calendar
        let next = CalendarLayout.upcoming(entry.events, after: entry.date, limit: 1).first
        VStack(alignment: .leading, spacing: 0) {
            EditorialCaption(entry.date.formatted(.dateTime.weekday(.wide)), size: 9, color: palette.golden)
            Text("\(cal.component(.day, from: entry.date))")
                .font(EditorialTheme.numeral(entry.showsEvents ? 54 : 70, weight: .semibold))
                .foregroundStyle(palette.primary)
                .monospacedDigit()
                .widgetAccentable()
            Text(entry.date.formatted(.dateTime.month(.wide)))
                .font(EditorialTheme.italic(entry.showsEvents ? 15 : 19))
                .foregroundStyle(palette.primary)
            Spacer(minLength: 4)
            if entry.showsEvents {
                Hairline().padding(.bottom, 4)
                if let next {
                    EditorialCaption(Self.whenLabel(next, now: entry.date, calendar: cal, uses24Hour: entry.uses24Hour), size: 8)
                    HStack(spacing: 5) {
                        Capsule().fill(palette.eventColor(next.color)).frame(width: 2.5, height: 13)
                        Text(next.title)
                            .font(EditorialTheme.italic(14))
                            .foregroundStyle(palette.primary)
                            .lineLimit(1)
                    }
                } else {
                    EditorialCaption("nothing coming up", size: 8)
                }
            } else {
                EditorialCaption("week \(cal.component(.weekOfYear, from: entry.date))", size: 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "15:00", "tue 09:30", "wed" for an all-day event, or "now · until 16:00".
    nonisolated static func whenLabel(_ e: CalendarEvent, now: Date, calendar: Calendar, uses24Hour: Bool) -> String {
        let dayOffset = calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                                to: calendar.startOfDay(for: max(e.start, now))).day ?? 0
        let day: String? = dayOffset == 0 ? nil : EditorialFormat.weekdayShort(e.start, calendar.timeZone).lowercased()
        let time = e.isAllDay ? "all day" : EditorialFormat.time(e.start, calendar.timeZone, uses24Hour: uses24Hour)
        if e.start <= now { return e.isAllDay ? "today" : "now · until " + EditorialFormat.time(e.end, calendar.timeZone, uses24Hour: uses24Hour) }
        return [day, e.isAllDay && day != nil ? nil : time].compactMap { $0 }.joined(separator: " ")
    }
}
