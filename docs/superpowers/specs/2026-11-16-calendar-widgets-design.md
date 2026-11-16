# Editorial Calendar — Design

Date: 2026-11-16
Status: Approved 2026-11-16 (design agreed in conversation)
Builds on: `2026-11-16-bornewidgets-design.md` (all of its goals, anti-goals and constraints still apply)

## Intent

A fourth Editorial design, **Editorial Calendar**, so the author's home screen has a calendar that matches the weather and clock widgets: the same almanac look, in light and dark, in all four sizes including the iOS 27 full-page widget. It shows the user's real events when allowed, and still looks complete as a pure date/month widget when not.

## Goals

- New category **Calendar** (library filter chip "Calendar"), new design `editorial.calendar` in sizes small, medium, large, extraLarge.
- Events from the iPhone's calendars (iCloud, Google, Exchange — whatever EventKit sees), opt-in.
- Without access, every size renders a complete date-only layout; no broken or empty-looking widget.
- App previews use the user's real events when access is granted, sample events otherwise (consistent with weather previews).

## Non-goals

- Creating/editing events, reminders, per-widget calendar selection, tapping into a specific event (tap opens the app like other widgets).
- Choosing which calendars to show (all visible calendars are used).

## Anti-goals

- A "please grant access" widget that looks unfinished. The date-only layout is a first-class design.
- Loud per-calendar colours that break the palette.
- Reading events in a way that leaks them anywhere outside the device (no network, no App Group copy of event data).

## Layout per size (agreed)

| Size | With events | Without access |
|---|---|---|
| Small | big serif date numeral, weekday + month in small caps, next event title + time | date block only |
| Medium | this week as a 7-day strip (today highlighted), next 2–3 events | week strip, larger |
| Large | month grid, today circled in gold, dot under days with events, today's events below | month grid, larger |
| Full page | month grid top, then agenda for the next 7 days grouped by day ("TUE 17 · 09:30 Standup"), moon phase per week as a small detail | month grid + quiet "Allow Calendar access in Borne" note |

Event colour: the event's calendar colour, toned down (reduced saturation/opacity) toward the palette. Tinted/clear Home Screens: monochrome like the other designs.

## Approaches

1. **Widget reads EventKit directly — chosen.** The extension queries `EKEventStore` each timeline load. Always fresh, event data never leaves EventKit. App extensions use the containing app's Calendar permission, so the app asks once.
2. App snapshots events into the App Group, widget reads the copy. Works without the extension touching EventKit, but goes stale whenever the app isn't opened and duplicates private data on disk — conflicts with the anti-goal.
3. Dates only. Simplest, but the agreed design includes events.

## How (decided)

- **BorneCore** (Foundation-only, macOS-testable): `CalendarEvent` model (id, title, start, end, isAllDay, colour as RGB), pure layout logic — month grid for a date + first weekday, 7-day week strip, agenda grouping for N days (multi-day and all-day events appear on each day they cover), "next event" after a moment, timeline reload dates. Sample events fixture.
- **EventKit reader** behind a `CalendarReading` protocol: fetches events in a range, reports access state (`granted / denied / notDetermined`). Requires full access (`requestFullAccessToEvents`), `NSCalendarsFullAccessUsageDescription` in the app.
- **BorneDesigns**: `CalendarEntry` (date, access, events, uses24Hour, firstWeekday), four Editorial views, registry wiring; `DesignRegistry.view` gains a `calendar:` parameter defaulting to `.sample`.
- **Widget timeline**: entries at now, each event start/end in the next 24h, and the next midnight; policy `.after` the last of those (capped at ~1h). The app reloads timelines when access changes and on `EKEventStoreChanged`.
- **App**: Settings gets a "Calendar" section — status, "Allow access" button, or "Open Settings" when denied. Detail view for the calendar design shows the same button.
- First weekday from the user's locale (`Calendar.current.firstWeekday`).

## Testing

- Unit (BorneCore): month grid (first weekday Monday vs Sunday, months starting on each weekday, 6-row months), week strip, agenda grouping incl. all-day and multi-day events, next event, reload dates.
- Design tests: every calendar card fits its widget size (existing parameterized fit test), render snapshots light/dark, with and without access.
- Manual: simulator (sample/no events) and the author's iPhone with real calendars.

## Left to the builder

- Exact typography sizes, how many events fit per size, truncation, event colour toning formula, empty-day copy ("Nothing scheduled").
