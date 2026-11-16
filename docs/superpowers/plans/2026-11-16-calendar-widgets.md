# Editorial Calendar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an Editorial Calendar design (small, medium, large, full page) showing the user's events when allowed and a complete date-only layout otherwise.

**Architecture:** Pure calendar math and the event model live in BorneCore (macOS-testable); an EventKit reader sits behind a protocol in BorneCore; views and `CalendarEntry` live in BorneDesigns and render through `DesignRegistry` like every other design; the widget extension reads EventKit directly on each timeline load.

**Tech Stack:** Swift 6, SwiftUI, WidgetKit, EventKit, Swift Testing, XcodeGen.

**Spec:** `docs/superpowers/specs/2026-11-16-calendar-widgets-design.md`

## Global Constraints

- iOS deployment target 26.0; full-page size gated `#available(iOS 27.0, macOS 27.0, *)` via existing `WidgetSize.family`.
- Design id / WidgetKit kind: `editorial.calendar`; name "Editorial Calendar"; category `.calendar` titled "Calendar".
- Event data never leaves EventKit: no App Group copy, no network.
- All colours from `EditorialPalette(mode, scheme)`; light and dark; monochrome in tinted/clear modes.
- First weekday from `Calendar.current.firstWeekday` (passed in, never read inside pure functions).
- Pure helpers on MainActor view types are `nonisolated`.

## Review Focus

1. All-day and multi-day events (e.g. a 3-day trip) — appear on every day they cover in agenda and grid dots, without a bogus time.
2. Months spanning 6 weeks (e.g. March 2026 with Monday start) — grid shows 6 rows and still fits the large widget.
3. Day with many events — lists truncate with "+N more" instead of overflowing.
4. Access denied / not determined — every size renders the date-only layout; the full page shows the quiet note.
5. Midnight rollover — timeline has an entry at the next midnight so "today" moves.

Tests for each are named in Tasks 1 and 3.

---

### Task 1: Calendar model, layout math, catalog entry

**Files:**
- Create: `BorneKit/Sources/BorneCore/Calendar/CalendarEvent.swift`, `BorneKit/Sources/BorneCore/Calendar/CalendarLayout.swift`, `BorneKit/Sources/BorneCore/Fixtures/SampleEvents.swift`
- Modify: `BorneKit/Sources/BorneCore/Registry/DesignCatalog.swift`
- Test: `BorneKit/Tests/BorneCoreTests/CalendarLayoutTests.swift`, `DesignCatalogTests.swift`

**Interfaces — Produces:**
- `public struct CalendarEvent: Identifiable, Hashable, Sendable { id: String; title: String; start: Date; end: Date; isAllDay: Bool; color: RGB }`, `public struct RGB: Hashable, Sendable { red, green, blue: Double }`
- `public enum CalendarAccess: Sendable { case granted, denied, notDetermined }`
- `public enum CalendarLayout`:
  - `monthGrid(for: Date, calendar: Calendar) -> [[Date?]]` — weeks × 7, nil outside the month, first column = `calendar.firstWeekday`.
  - `week(containing: Date, calendar: Calendar) -> [Date]` — 7 day starts.
  - `agenda(_ events: [CalendarEvent], from: Date, days: Int, calendar: Calendar) -> [(day: Date, events: [CalendarEvent])]` — every day in range, events sorted all-day first then by start; events covering several days appear on each.
  - `upcoming(_ events: [CalendarEvent], after: Date, limit: Int) -> [CalendarEvent]` — not yet ended, by start.
  - `daysWithEvents(_ events: [CalendarEvent], calendar: Calendar) -> Set<Date>` — day starts.
  - `reloadDates(events: [CalendarEvent], now: Date, calendar: Calendar) -> [Date]` — now, starts/ends within 24h, next midnight; sorted, unique.
- `WidgetCategory.calendar` ("Calendar"); `DesignCatalog.editorialCalendar` with sizes `[.small, .medium, .large, .extraLarge]`, appended to `all`.
- `CalendarEvent.samples(around: Date, calendar: Calendar) -> [CalendarEvent]` — ~8 events over the next 7 days incl. one all-day and one 3-day event.

- [ ] **Step 1: failing tests** (UTC calendar, `firstWeekday` set explicitly):
  - `monthGridMondayStart`: Nov 2026 with firstWeekday 2 → first row `[nil, nil, nil, nil, nil, nil, Nov 1]`, 6 rows.
  - `monthGridSundayStart`: Nov 2026 with firstWeekday 1 → first row starts Nov 1, 5 rows.
  - `monthGridSixRows`: Mar 2026, firstWeekday 2 → 6 rows (Review Focus 2).
  - `weekContainingMondayStart`: Wed 18 Nov → Mon 16 … Sun 22.
  - `agendaMultiDayEventOnEachDay`: event Tue 09:00 → Thu 18:00 appears on Tue, Wed, Thu (Review Focus 1).
  - `agendaAllDayFirst`: all-day sorts before a 08:00 event.
  - `agendaIncludesEmptyDays`: 7 days requested → 7 groups.
  - `upcomingSkipsEnded`.
  - `reloadDatesIncludeNextMidnight` (Review Focus 5) and event start/end within 24h, none beyond.
  - Catalog: `cards(category: .calendar).count == 4`; total cards updated (8 → 12).
- [ ] **Step 2:** `swift test --package-path BorneKit --filter "CalendarLayout|DesignCatalog"` → FAIL (types missing).
- [ ] **Step 3:** implement the Produces list.
- [ ] **Step 4:** same command → PASS; full `swift test --package-path BorneKit` → PASS.
- [ ] **Step 5:** commit `feat(core): calendar model, layout math and catalog entry`.

### Task 2: EventKit reader

**Files:** Create `BorneKit/Sources/BorneCore/Calendar/EventKitCalendarReader.swift`; Test `BorneKit/Tests/BorneCoreTests/CalendarReaderTests.swift`

**Interfaces — Produces:**
- `public protocol CalendarReading: Sendable { var access: CalendarAccess { get }; func events(from: Date, to: Date) -> [CalendarEvent] }`
- `public struct EventKitCalendarReader: CalendarReading` (maps `EKAuthorizationStatus.fullAccess` → `.granted`, `.denied/.restricted/.writeOnly` → `.denied`, `.notDetermined` → `.notDetermined`; colour from `EKCalendar.cgColor` converted to sRGB `RGB`; returns `[]` unless granted), plus `public static func requestAccess() async -> CalendarAccess`.
- `static func access(for: EKAuthorizationStatus) -> CalendarAccess` (nonisolated, tested).

- [ ] Step 1: test `accessMapping` for all five statuses. Step 2: FAIL. Step 3: implement. Step 4: PASS + full suite. Step 5: commit `feat(core): EventKit calendar reader`.

### Task 3: Calendar views

**Files:**
- Modify: `BorneKit/Sources/BorneDesigns/Entries.swift` (add `CalendarEntry`), `DesignRegistry.swift` (add `calendar: CalendarEntry = .sample` parameter and four cases), `Styles/Editorial/Theme.swift` (`EditorialPalette.eventColor(_ rgb: RGB) -> Color` — toned toward palette; primary in non-fullColor modes)
- Create: `Styles/Editorial/Calendar/{EditorialCalendarSmall,Medium,Large,ExtraLarge}.swift`, `Styles/Editorial/Components/MonthGrid.swift`, `Components/WeekStrip.swift`, `Components/EventRow.swift`
- Test: `BorneKit/Tests/BorneDesignsTests/CalendarViewTests.swift`; `RenderSnapshots.swift` and `LayoutFitTests.swift` pass a calendar entry (with events, and `.noAccess`).

**Interfaces — Produces:**
- `public struct CalendarEntry: TimelineEntry, Sendable { date; access: CalendarAccess; events: [CalendarEvent]; uses24Hour: Bool; calendar: Calendar }`, `static var sample` (granted, `CalendarEvent.samples`), `static func noAccess(at: Date) -> CalendarEntry`.
- `EventRow.visible(_ events: [CalendarEvent], limit: Int) -> (shown: [CalendarEvent], more: Int)` (nonisolated).

Layouts follow the spec table. Large: month grid + today's events (limit 3, "+N more"). Full page: month grid, then 7-day agenda (≤2 events per day, "+N more"; empty day shows "Nothing scheduled" in secondary), moon glyph per agenda week; without access, the note "Allow Calendar access in Borne" in a caption.

- [ ] Step 1: failing tests — `visibleTruncatesWithMore` ([5 events], limit 3 → 3 shown, more 2) (Review Focus 3); fit test covers new cards automatically, add `calendarFitsOnIPhone18Pro` for large (349.67×365, 6-row month — render with date in Mar 2026) and extraLarge (349.67×565.67), both with sample and with `.noAccess` (Review Focus 2, 4).
- [ ] Step 2: FAIL. Step 3: implement views + registry. Step 4: PASS; render `RENDER_DIR=… swift test --package-path BorneKit --filter renderAllCards`, inspect light/dark PNGs for all four sizes with and without access.
- [ ] Step 5: commit `feat(designs): Editorial Calendar in four sizes`.

### Task 4: Widget, app wiring, device build

**Files:**
- Create: `WidgetExtension/Providers/CalendarProvider.swift`
- Modify: `WidgetExtension/Widgets/EditorialWidgets.swift` (+`EditorialCalendarWidget`), `BorneWidgetBundle.swift`, `WidgetExtension/Widgets/DesignWidgetView.swift` (`calendar:` param), `App/AppModel.swift` (`calendarAccess`, `requestCalendarAccess()`, `calendarEntry(at:)`; observe `EKEventStoreChanged` → reload timelines), `App/Library/PreviewCard.swift`, `App/Settings/SettingsView.swift` (Calendar section), `App/Detail/DesignDetailView.swift` (allow-access button for calendar design), `project.yml` (`NSCalendarsFullAccessUsageDescription: Borne shows your upcoming events in its Calendar widgets.` on app and extension), `README.md` (designs table).

**Provider:** entries at `CalendarLayout.reloadDates` (each with events from now−1 day to now+8 days via `EventKitCalendarReader`), policy `.after(min(last reload date, now + 1h))`; placeholder/snapshot use `.sample`.

- [ ] Step 1: `swift test --package-path BorneKit` → PASS.
- [ ] Step 2: `./build.sh <ios27-simulator-udid>` → BUILD SUCCEEDED; also an iOS 26 simulator.
- [ ] Step 3: install on sim (bundle id from `$(BUNDLE_PREFIX).bornewidgets`), grant calendar via Settings button, screenshot library filtered to Calendar.
- [ ] Step 4: device build + install on the author's iPhone.
- [ ] Step 5: commit `feat: Editorial Calendar widget with EventKit events`.
