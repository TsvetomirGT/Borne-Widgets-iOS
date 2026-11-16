# Borne Widgets — Design

Date: 2026-11-16
Status: Approved 2026-11-16

**Run targets:** simulator first; must also work on a real iPhone later. `project.yml` leaves `DEVELOPMENT_TEAM` empty (simulator builds sign locally); a gitignored `Local.xcconfig` (with a committed `Local.xcconfig.example`) supplies team ID and bundle prefix for device builds, so no personal IDs land in the repo. App Group id derives from the bundle prefix.

## Intent

A personal iOS app that acts as a **library of beautifully crafted home-screen widgets** (weather, time, more later). Built first for the author's own home screen, second as a portfolio piece, and likely published as open source on GitHub. Visual craft is the point; code readability matters because strangers will read it.

Inspiration: a dark "editorial" weather card — large serif numerals, italic serif condition text, small-caps monospaced labels, hairline rules, an 18-hour temperature curve with hatched rain segments, a daily forecast strip with min/max range bars, a sun arc with sunrise/sunset, moon phase with "golden hour" time, a one-sentence natural-language summary, location and date in small caps, thin gold frame.

## Goals

- In-app library of widget **designs**, filterable by **size** (small / medium / large) and **category** (Clock, Weather, Sun & Moon; more later). Style is the third axis (see below).
- Each design is a separate entry in the iOS widget picker, with its own preview.
- App previews render with the **same SwiftUI view code** the widget uses, so the library is truthful.
- Shared settings in the app (location, units, 12/24h, world-clock cities) consumed by all widgets.
- First style: **Dark Editorial**, faithful in spirit to the reference.
- Runs from a fresh clone with no API keys and no paid developer account.

## Non-goals (v1)

- Multiple styles shipped (architecture supports them; only Editorial ships).
- iPad extra-large, Lock Screen, StandBy, watchOS, Live Activities.
- Per-widget configuration via the widget edit sheet (settings live in the app).
- Notifications, accounts, sync, monetization, App Store release.
- Localization beyond English (strings kept in a String Catalog so it's possible later).

## Anti-goals

- App chrome that fakes glass with custom blurs or ignores Liquid Glass conventions (glass on content, opaque custom bars).
- Generic-looking widgets. A widget that is "correct" but looks like a template is a failure.
- An in-app preview that differs from what lands on the home screen.
- A setup that requires secrets or paid accounts for someone cloning the repo.
- Style code tangled together, so adding a new style means touching existing ones.

## Constraints

- Apps cannot place widgets; users add them from the system widget picker. The app is a showroom + settings + "how to add" guide.
- Widgets render static snapshots on a timeline; no continuous animation. Clocks advance via per-minute timeline entries (or `Text(date, style:)` where it fits).
- Widget reload budget is limited (~40–70 reloads/day); weather fetched at most every 30 min, served from a shared cache otherwise.
- Toolchain: Xcode 27.2, iOS deployment target **26.0**, Swift 6, SwiftUI, WidgetKit.
- Weather: **Open-Meteo** (free, no key). Forecast endpoint for current/hourly/daily; geocoding endpoint for manual city search.

## Approaches considered

1. **One picker entry per design (category × style).** Library maps 1:1 to the picker; each style isolated in code. Picker grows long with many styles.
2. **One picker entry per category, style chosen in the widget edit sheet.** Short picker, but previews show only the default style and all styles share one config schema.
3. **Hybrid — chosen.** Option 1 for picker entries (one widget kind per design, own preview), plus a shared settings layer in the app (location, units, time format, cities) stored in the App Group that every widget reads. Chosen because it keeps the library and picker identical, isolates styles, and avoids duplicating common settings per widget.

## Architecture

### Targets (generated with XcodeGen from `project.yml`; `.xcodeproj` git-ignored)

- **BorneWidgets** (iOS app): library, design detail, settings.
- **BorneWidgetsExtension** (WidgetKit extension): a `WidgetBundle` with one `Widget` per design.
- **BorneKit** (local Swift package, linked by both): models, Open-Meteo client, cache, settings store, astronomy math, design registry, and all widget views/styles. Unit tests live here.

Shared App Group: `group.<bundle-prefix>.bornewidgets` (bundle prefix configurable in `project.yml`; builder picks a placeholder like `dev.borne`).

### Core concepts

- `WidgetCategory`: `.clock`, `.weather`, `.sunMoon` (enum, extensible).
- `WidgetStyle`: `.editorial` (enum, extensible).
- `WidgetDesign`: id, display name, category, style, supported `WidgetFamily` set, short description, and a view builder taking `(family, entry)`. A static `DesignRegistry.all` lists every design; both the app library and the extension's bundle derive from it (the bundle still needs explicit `Widget` structs — the registry supplies their views and metadata).
- Each style lives in its own folder (`Styles/Editorial/…`) with its own theme tokens (colors, fonts, spacing) and views.

### Data

- `WeatherSnapshot`: location name, fetchedAt, current (temp, feels-like, condition code, humidity, UV, wind speed + direction), hourly (next 24h: time, temp, precip probability, precip amount, condition code), daily (7 days: date, min, max, condition code, precip probability, sunrise, sunset).
- `OpenMeteoClient` (async/await, `URLSession`), decoding into DTOs then mapping to the model. WMO weather codes mapped to condition text + SF Symbol.
- `WeatherStore`: reads/writes cached snapshot as JSON in the App Group container; returns cache if < 30 min old, otherwise fetches; on failure returns stale cache flagged `isStale`.
- `SettingsStore` (App Group `UserDefaults`): location mode (`.current` / `.manual(name, lat, lon)`), last resolved coordinates + place name, temperature unit (°C default), wind unit, 24h clock (default on), world-clock cities (up to 3, each a name + time zone id; default list e.g. London, New York, Tokyo).
- Location: the **app** requests When-In-Use location and reverse-geocodes, storing coordinates + name in the App Group. Widgets use stored coordinates only (no location permission in the extension). Manual city via Open-Meteo geocoding search in Settings.
- Astronomy (local, no network): moon phase + illumination + phase name from date (standard synodic-month algorithm); golden hour = sunset − 40 min (simple approximation, documented as such).
- Summary sentence: generated locally from hourly/daily data via small templated rules (e.g., "No rain in the next 18 hours. Tomorrow 15°, rain likely."). Rules table is the builder's to design; must cover rain soon / dry / temperature trend.

### Timelines

- Weather & Sun/Moon: `TimelineProvider` loads snapshot from `WeatherStore`, emits one entry now, policy `.after(now + 30 min)`.
- Clock: entries for each minute of the next 60 min, policy `.atEnd`. Analog hands drawn from entry date.
- App triggers `WidgetCenter.shared.reloadAllTimelines()` when settings change or after a fresh fetch.
- Placeholder and gallery previews use bundled sample data (a fixed `WeatherSnapshot.sample`), so the picker looks right with no network.

## v1 widget designs (all Editorial style)

| Design | Small | Medium | Large |
|---|---|---|---|
| Editorial Weather | big temp, italic condition, H/L, place | temp block + 18h curve w/ hatched rain + feels/rain/humidity row | full reference layout: header stats, 18h curve, 6-day strip w/ range bars, sun arc, moon phase + golden hour, summary sentence, place + date |
| Editorial Clock | analog face, hairline ticks, serif numerals | large serif digital time + weekday/date in small caps | world clocks: up to 3 cities, time + offset + day/night mark |
| Editorial Sun & Moon | sun arc w/ sunrise/sunset + moon phase glyph | (not in v1) | (not in v1) |

Editorial theme tokens: near-black blue-slate background with faint topographic contour texture (drawn as subtle paths or a bundled vector asset), off-white primary text, muted grey secondary, accent blue for rain, warm orange for "now"/golden, thin gold border inset. Fonts: system **New York** serif (`.serif` design) for numerals/condition text, **SF Mono** small caps for labels — no bundled fonts, avoiding licensing. Hatching drawn with SwiftUI `Path`/`Canvas`.

Widget views must respect `widgetRenderingMode` (fullColor primary; accented/vibrant should remain legible) and use `containerBackground`.

## App UI

**Design language: native Liquid Glass (iOS 26+).** Only Apple's native Liquid Glass material and APIs are used — no imitation via `.ultraThinMaterial`, `UIVisualEffectView`, custom blurs, gradients or overlays. The app chrome follows Apple's Liquid Glass principles; the widget previews are the content and keep their own style (Editorial etc.). Principles applied:
- Glass is for the **navigation/control layer only**, floating above content — never on content cards themselves.
- Standard containers adopt glass automatically: `TabView` (tabs: Library, Settings; plus a `Tab(role: .search)` for searching designs), `NavigationStack` toolbars, sheets.
- Custom controls (filter chips, "How to add" button) use `.glassEffect()` / `.buttonStyle(.glass)` / `.glassProminent` for the primary action, grouped in a `GlassEffectContainer` so neighbouring chips blend and morph; selected chip state animates with `glassEffectID` + namespace.
- Filters float as a glass bar pinned over the scrolling grid (content scrolls underneath; scroll-edge effect handles legibility). Tab bar minimizes on scroll (`tabBarMinimizeBehavior(.onScrollDown)`).
- Content goes edge-to-edge behind the glass; no custom opaque bars or backgrounds that fight the system material. Respect Reduce Transparency / Increase Contrast automatically by using system APIs rather than hand-rolled blur.
- Background behind the grid: a deep, subtly-toned backdrop so glass and the dark previews both read well; supports light and dark appearance.
- Widgets themselves must look right in the iOS 26 home-screen **clear and tinted** modes: handle `widgetRenderingMode == .accented`, mark key elements with `widgetAccentable()`, and use `widgetAccentedRenderingMode` on any images.

- **Library (home):** title; three filter rows of chips — Size (All/Small/Medium/Large), Category (All/Clock/Weather/Sun & Moon), Style (All/Editorial; hidden until >1 style exists is acceptable). Grid of preview cards, one card per design × supported size, rendered at true widget proportions using live cached data (sample data fallback). Filters combine with AND.
- **Design detail:** all sizes of that design side by side, description, "How to add" steps (long-press home screen → + → search "Borne").
- **Settings:** location (current / search city), units, 24h toggle, world-clock cities, "Refresh weather now", data attribution "Weather data by Open-Meteo.com" (required by their license, CC BY 4.0).
- App chrome uses Liquid Glass (above), not the Editorial look; Editorial lives inside the previews.

## Testing

- Unit tests (BorneKit): Open-Meteo decoding against a recorded JSON fixture; WMO code mapping; moon phase for known dates; summary-sentence rules; registry filtering by size/category/style; cache freshness logic.
- Manual: build + run on iPhone 17 Pro simulator (iOS 26.3) and iOS 27 simulator; add each widget size to home screen; check light/dark and tinted modes.
- SwiftUI `#Preview` for every widget size with sample data.

## Repo

- `README.md` with screenshots, build steps (`brew install xcodegen && xcodegen`), Open-Meteo attribution. License: MIT (author may change).
- `.gitignore` for Xcode/XcodeGen output.

## Left to the builder

- Exact layout metrics, typography sizes, contour texture technique.
- Summary-sentence rule table.
- File/folder naming inside BorneKit beyond the Styles/<Style> convention.
- Bundle identifier prefix placeholder.
- Error/empty states (stale data indicator, no-location state) — keep them on-style and quiet.
