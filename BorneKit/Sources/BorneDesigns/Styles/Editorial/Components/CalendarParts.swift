import BorneCore
import SwiftUI
import WidgetKit

/// The month as a grid of serif day numbers under weekday initials.
/// Today is ringed in gold; days with events carry a small dot.
struct MonthGrid: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let date: Date
    let calendar: Calendar
    var eventDays: Set<Date> = []
    var numeralSize: CGFloat = 13
    var rowHeight: CGFloat = 22

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let today = calendar.startOfDay(for: date)
        let rows = CalendarLayout.monthGrid(for: date, calendar: calendar)
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(Self.weekdayInitials(calendar).enumerated()), id: \.offset) { _, initial in
                    EditorialCaption(initial, size: 8).frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 3)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, day in
                        ZStack {
                            if let day {
                                let isToday = day == today
                                if isToday {
                                    Circle().stroke(palette.gold, lineWidth: 1.2)
                                        .frame(width: rowHeight - 2, height: rowHeight - 2)
                                        .widgetAccentable()
                                }
                                Text("\(calendar.component(.day, from: day))")
                                    .font(EditorialTheme.numeral(numeralSize, weight: isToday ? .bold : .regular))
                                    .foregroundStyle(isToday ? palette.golden : (day < today ? palette.secondary : palette.primary))
                                    .monospacedDigit()
                                if eventDays.contains(day) {
                                    Circle().fill(isToday ? palette.golden : palette.secondary)
                                        .frame(width: 3, height: 3)
                                        .offset(y: rowHeight / 2 - 2)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: rowHeight)
                    }
                }
            }
        }
    }

    /// Weekday initials starting at the calendar's first weekday.
    nonisolated static func weekdayInitials(_ calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
    }
}

/// This week as seven columns: weekday, day number, event dot.
struct WeekStrip: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let date: Date
    let calendar: Calendar
    var eventDays: Set<Date> = []
    var numeralSize: CGFloat = 15

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let today = calendar.startOfDay(for: date)
        let initials = MonthGrid.weekdayInitials(calendar)
        HStack(spacing: 0) {
            ForEach(Array(CalendarLayout.week(containing: date, calendar: calendar).enumerated()), id: \.offset) { i, day in
                let isToday = day == today
                VStack(spacing: 2) {
                    EditorialCaption(initials[i], size: 8, color: isToday ? palette.golden : nil)
                    ZStack {
                        if isToday {
                            Circle().stroke(palette.gold, lineWidth: 1.2)
                                .frame(width: numeralSize + 9, height: numeralSize + 9)
                                .widgetAccentable()
                        }
                        Text("\(calendar.component(.day, from: day))")
                            .font(EditorialTheme.numeral(numeralSize, weight: isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? palette.golden : (day < today ? palette.secondary : palette.primary))
                            .monospacedDigit()
                    }
                    .frame(height: numeralSize + 9)
                    Circle().fill(eventDays.contains(day) ? palette.secondary : .clear).frame(width: 3, height: 3)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// One event: a calendar-coloured rule, its time (or "all day") and title.
struct EventRow: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let event: CalendarEvent
    let calendar: Calendar
    let uses24Hour: Bool
    var titleSize: CGFloat = 13
    var timeWidth: CGFloat = 48
    /// Replaces the time, e.g. "tomorrow 09:30".
    var label: String? = nil

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Capsule().fill(palette.eventColor(event.color))
                .frame(width: 2.5, height: titleSize)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 2 }
            EditorialCaption(label ?? Self.timeLabel(event, calendar: calendar, uses24Hour: uses24Hour), size: 8)
                .frame(width: timeWidth, alignment: .leading)
            Text(event.title)
                .font(EditorialTheme.numeral(titleSize))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    nonisolated static func timeLabel(_ event: CalendarEvent, calendar: Calendar, uses24Hour: Bool) -> String {
        event.isAllDay ? "all day" : EditorialFormat.time(event.start, calendar.timeZone, uses24Hour: uses24Hour)
    }

    /// The first `limit` events and how many were left out.
    nonisolated static func visible(_ events: [CalendarEvent], limit: Int) -> (shown: [CalendarEvent], more: Int) {
        (Array(events.prefix(limit)), max(0, events.count - limit))
    }
}

/// Events in a column, ending in "+N more" when cut short, or a quiet line when empty.
struct EventList: View {
    let events: [CalendarEvent]
    let limit: Int
    let calendar: Calendar
    let uses24Hour: Bool
    var titleSize: CGFloat = 13
    var spacing: CGFloat = 5
    var emptyText = "nothing scheduled"

    var body: some View {
        let v = EventRow.visible(events, limit: limit)
        VStack(alignment: .leading, spacing: spacing) {
            if v.shown.isEmpty {
                EditorialCaption(emptyText, size: 8)
            }
            ForEach(v.shown) { e in
                EventRow(event: e, calendar: calendar, uses24Hour: uses24Hour, titleSize: titleSize)
            }
            if v.more > 0 {
                EditorialCaption("+\(v.more) more", size: 8).padding(.leading, 8.5)
            }
        }
    }
}
