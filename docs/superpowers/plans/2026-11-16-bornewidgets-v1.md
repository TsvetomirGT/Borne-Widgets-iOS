# Borne Widgets v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iOS app that is a Liquid-Glass library of home-screen widgets, shipping a Dark Editorial style for Weather (S/M/L), Clock (S/M/L) and Sun & Moon (S), backed by Open-Meteo.

**Architecture:** XcodeGen project with an app target and a WidgetKit extension, both linking a local Swift package `BorneKit`. `BorneKit` has two libraries: `BorneCore` (Foundation-only logic: models, Open-Meteo client, cache, settings, astronomy, summary text, design registry metadata — unit-tested with `swift test` on macOS) and `BorneDesigns` (SwiftUI/WidgetKit views per style, shared by app previews and widgets). App and extension share data through an App Group.

**Tech Stack:** Swift 6.4, SwiftUI, WidgetKit, Swift Testing, XcodeGen, Open-Meteo REST, CoreLocation + MapKit (reverse geocode).

**Spec:** `docs/superpowers/specs/2026-11-16-bornewidgets-design.md`

## Global Constraints

- iOS deployment target **26.0**; build with Xcode 27.2 SDK. `BorneKit` platforms: `.iOS(.v26), .macOS(.v26)` (macOS only so `swift test` runs).
- Swift 6 language mode, strict concurrency.
- Simulator: `platform=iOS Simulator,name=iPhone 17,OS=26.3`. Also smoke-test on `iPhone 18 Pro,OS=27.0`.
- No API keys, no paid account needed. `DEVELOPMENT_TEAM` empty in committed config; `Config/Local.xcconfig` (gitignored) overrides `DEVELOPMENT_TEAM` and `BUNDLE_PREFIX`; `Config/Local.xcconfig.example` committed.
- Default `BUNDLE_PREFIX = dev.borne`. App bundle id `$(BUNDLE_PREFIX).bornewidgets`, extension `$(BUNDLE_PREFIX).bornewidgets.widgets`, App Group `group.$(BUNDLE_PREFIX).bornewidgets`.
- Weather cache freshness: **30 min**. Timeline policy for weather/sun-moon: `.after(now + 30 min)`. Clock: 60 per-minute entries, `.atEnd`.
- Temperatures always fetched/stored in °C; converted at display. Defaults: °C, km/h, 24h clock on, world clocks London (`Europe/London`), New York (`America/New_York`), Tokyo (`Asia/Tokyo`), max 3.
- Golden hour = sunset − 40 min.
- Fonts: system New York (`.serif` design) for numerals/condition text; SF Mono (`.monospaced`) small caps for labels. No bundled fonts.
- App chrome: **native Liquid Glass only** (`TabView`, toolbars, `.glassEffect`, `.buttonStyle(.glass/.glassProminent)`, `GlassEffectContainer`, `glassEffectID`). Never `.ultraThinMaterial`, `UIVisualEffectView`, custom blur. Glass never on preview cards.
- Attribution string in Settings and README: "Weather data by Open-Meteo.com" (CC BY 4.0).
- Widget kinds = design ids: `editorial.weather`, `editorial.clock`, `editorial.sunmoon`.

## Review Focus

1. **User changes city** — cached snapshot for the old place must not be served; widget shows new city after reload. (Test in Task 5.)
2. **No location yet / permission denied** — widgets show a quiet on-style "Open Borne to set a location" state, never crash or show sample data as real. (Tests in Task 5 + view in Task 9.)
3. **Manual city in another time zone** — hourly/daily times parse in the *location's* UTC offset, sunrise shows local-to-city time. (Test in Task 4.)
4. **Rounding/sign** — `-0.4` renders `0°` (never `-0°`), `-3.6` → `-4°`, °F conversion correct. (Test in Task 3.)
5. **Old cache** — "next 18 hours" starts at the current hour, not the first element of a fetch made hours ago. (Test in Task 3.)

---

## File Structure

```
.gitignore  README.md  LICENSE  project.yml
Config/Base.xcconfig  Config/Local.xcconfig.example
BorneKit/Package.swift
BorneKit/Sources/BorneCore/
  Models/WeatherSnapshot.swift      – snapshot + nested Current/Hour/Day, slicing helpers
  Models/WeatherCondition.swift     – WMO code → condition text + SF Symbol
  Models/Formatting.swift           – TemperatureUnit, WindUnit, temperature/wind formatting
  Models/Location.swift             – SavedLocation, Coordinate
  Weather/OpenMeteoClient.swift     – forecast + geocoding requests, DTOs, mapping
  Weather/WeatherStore.swift        – cache + freshness + fallback
  Settings/AppGroup.swift           – group id lookup, container URL, shared defaults
  Settings/SettingsStore.swift      – persisted user settings
  Astronomy/MoonPhase.swift         – phase, illumination, name
  Astronomy/SunTimes.swift          – golden hour, sun progress 0…1
  Text/WeatherSummary.swift         – summary sentence rules
  Registry/DesignCatalog.swift      – WidgetCategory, WidgetStyle, WidgetSize, DesignInfo, DesignCatalog, filtering
  Fixtures/SampleData.swift         – WeatherSnapshot.sample (Lisbon-like data)
BorneKit/Sources/BorneDesigns/
  DesignRegistry.swift              – DesignInfo → view builder; WidgetSize ↔ WidgetFamily
  Entries.swift                     – WeatherEntry, ClockEntry
  Styles/Editorial/Theme.swift      – colors, fonts, spacing tokens
  Styles/Editorial/Components/*.swift – ContourBackground, FrameBorder, StatLabel, TemperatureCurve, ForecastStrip, SunArc, MoonGlyph, AnalogFace
  Styles/Editorial/Weather/EditorialWeather{Small,Medium,Large}.swift
  Styles/Editorial/Clock/EditorialClock{Small,Medium,Large}.swift
  Styles/Editorial/SunMoon/EditorialSunMoonSmall.swift
  Styles/Editorial/EmptyStateView.swift
BorneKit/Tests/BorneCoreTests/*.swift + Fixtures/forecast.json, geocoding.json
App/  BorneWidgetsApp.swift, RootView.swift, Library/*, Detail/*, Settings/*, Location/LocationService.swift, Info.plist, BorneWidgets.entitlements
WidgetExtension/  BorneWidgetBundle.swift, Providers/{WeatherProvider,ClockProvider}.swift, Widgets/*.swift, Info.plist, BorneWidgetsExtension.entitlements
```

---

### Task 1: Repo + BorneKit package skeleton

**Files:** Create `.gitignore`, `BorneKit/Package.swift`, `BorneKit/Sources/BorneCore/BorneCore.swift`, `BorneKit/Sources/BorneDesigns/BorneDesigns.swift`, `BorneKit/Tests/BorneCoreTests/SmokeTests.swift`

**Interfaces:** Produces libraries `BorneCore`, `BorneDesigns` (depends on BorneCore); test target `BorneCoreTests` with resources `.copy("Fixtures")`.

- [ ] **Step 1:** `git init`; `.gitignore` covers `*.xcodeproj`, `.build/`, `DerivedData/`, `xcuserdata/`, `.DS_Store`, `Config/Local.xcconfig`, `.swiftpm/`.
- [ ] **Step 2:** Package.swift (swift-tools-version 6.2), platforms per Global Constraints. Smoke test `@Test func packageBuilds() { #expect(BorneCore.version == "0.1.0") }`.
- [ ] **Step 3:** Run `cd BorneKit && swift test` → FAIL (no `version`). Add `public enum BorneCore { public static let version = "0.1.0" }`. Re-run → PASS.
- [ ] **Step 4:** Commit `chore: init repo and BorneKit package` (includes `docs/`).

### Task 2: Xcode project, app + extension shells, App Group

**Files:** Create `project.yml`, `Config/Base.xcconfig`, `Config/Local.xcconfig.example`, `App/BorneWidgetsApp.swift`, `App/Info.plist`, `App/BorneWidgets.entitlements`, `WidgetExtension/BorneWidgetBundle.swift`, `WidgetExtension/Info.plist`, `WidgetExtension/BorneWidgetsExtension.entitlements`, `BorneKit/Sources/BorneCore/Settings/AppGroup.swift`

**Interfaces:**
- Produces: `public enum AppGroup { static var identifier: String; static var containerURL: URL; static var defaults: UserDefaults }` — identifier read from Info.plist key `BorneAppGroup` (value `group.$(BUNDLE_PREFIX).bornewidgets` in both plists). If `containerURL(forSecurityApplicationGroupIdentifier:)` returns nil, fall back to `FileManager` caches dir and `UserDefaults.standard` and `os_log` a warning (keeps `swift test` and misconfigured builds alive).

- [ ] **Step 1:** `Base.xcconfig`: `BUNDLE_PREFIX = dev.borne`, `DEVELOPMENT_TEAM =`, `CODE_SIGN_STYLE = Automatic`, last line `#include? "Local.xcconfig"`. Example file shows both keys.
- [ ] **Step 2:** `project.yml`: name `BorneWidgets`; `configFiles` Debug/Release → `Config/Base.xcconfig`; local package `BorneKit`; target `BorneWidgets` (application, iOS 26.0, sources `App`, deps BorneCore, BorneDesigns, target BorneWidgetsExtension embedded); target `BorneWidgetsExtension` (app-extension, sources `WidgetExtension`, deps BorneCore, BorneDesigns, Info.plist `NSExtension.NSExtensionPointIdentifier = com.apple.widgetkit-extension`). App Info.plist includes `NSLocationWhenInUseUsageDescription` = "Borne uses your location to show local weather in your widgets." Both entitlements: `com.apple.security.application-groups = [group.$(BUNDLE_PREFIX).bornewidgets]`.
- [ ] **Step 3:** App shows `Text("Borne")`; bundle has one placeholder `StaticConfiguration` widget.
- [ ] **Step 4:** Run `xcodegen && xcodebuild -project BorneWidgets.xcodeproj -scheme BorneWidgets -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3' build` → `** BUILD SUCCEEDED **`.
- [ ] **Step 5:** Install + launch on booted simulator (`xcrun simctl install booted <app>`; `xcrun simctl launch booted dev.borne.bornewidgets`); confirm app launches and placeholder widget appears in widget gallery. In app, log `AppGroup.containerURL` and confirm it's the group container, not fallback.
- [ ] **Step 6:** Commit `chore: add XcodeGen project with app and widget extension`.

### Task 3: Weather model, conditions, formatting, sample data

**Files:** Create `Models/WeatherSnapshot.swift`, `Models/WeatherCondition.swift`, `Models/Formatting.swift`, `Models/Location.swift`, `Fixtures/SampleData.swift`; Test `Tests/BorneCoreTests/ModelTests.swift`

**Interfaces — Produces (all `public`, `Codable, Sendable, Equatable`):**
- `struct Coordinate { latitude: Double; longitude: Double; func isNear(_ other: Coordinate) -> Bool }` — true when both differ < 0.01°.
- `struct SavedLocation { name: String; coordinate: Coordinate; timeZoneID: String }`
- `struct WeatherSnapshot { location: SavedLocation; fetchedAt: Date; utcOffsetSeconds: Int; current: Current; hourly: [Hour]; daily: [Day] }`
  - `Current { temperature, apparentTemperature: Double; humidity: Int; uvIndex: Double; windSpeed: Double; windDirection: Double; condition: WeatherCondition }`
  - `Hour { time: Date; temperature: Double; precipitationProbability: Int; precipitation: Double; condition: WeatherCondition }`
  - `Day { date: Date; min, max: Double; condition: WeatherCondition; precipitationProbability: Int; sunrise, sunset: Date }`
  - `func hours(from now: Date, count: Int) -> [Hour]` — starts at the hour containing `now`.
  - `func today(at now: Date) -> Day?`, `func days(after now: Date, count: Int) -> [Day]`
  - `var timeZone: TimeZone` (from `utcOffsetSeconds`)
- `enum WeatherCondition: clear, mainlyClear, partlyCloudy, cloudy, fog, drizzle, freezingDrizzle, rain, heavyRain, freezingRain, snow, showers, snowShowers, thunderstorm, thunderstormHail` with `init(wmoCode: Int)`, `var text: String`, `var symbolName: String`, `var isSnow: Bool`.
  - WMO map: 0 clear "Clear" `sun.max`; 1 mainlyClear "Mostly clear" `sun.max`; 2 partlyCloudy "Partly cloudy" `cloud.sun`; 3 cloudy "Cloudy" `cloud`; 45,48 fog "Fog" `cloud.fog`; 51,53,55 drizzle "Drizzle" `cloud.drizzle`; 56,57 freezingDrizzle "Freezing drizzle" `cloud.sleet`; 61,63 rain "Rain" `cloud.rain`; 65 heavyRain "Heavy rain" `cloud.heavyrain`; 66,67 freezingRain "Freezing rain" `cloud.sleet`; 71,73,75,77 snow "Snow" `cloud.snow`; 80,81,82 showers "Showers" `cloud.rain`; 85,86 snowShowers "Snow showers" `cloud.snow`; 95 thunderstorm "Thunderstorm" `cloud.bolt.rain`; 96,99 thunderstormHail "Thunder & hail" `cloud.bolt.rain`; unknown → cloudy.
- `enum TemperatureUnit: String { celsius, fahrenheit }` with `func format(_ celsius: Double) -> String` → `"13°"` (rounded, never `-0`). `enum WindUnit: String { kmh, mph, ms }` with `func format(_ kmh: Double) -> String` (`"12 km/h"`), and `static func compass(_ degrees: Double) -> String` (8-point: N, NE, …, NW).
- `extension WeatherSnapshot { static let sample: WeatherSnapshot }` — location "Lisbon", now-relative times; current 13°, feels 12°, humidity 90, UV 2, wind 9 km/h NW, cloudy; 24 hours with a rise to 13° and precip ≥ 50 % in hours 12–17; 7 days (17/11, 15/12, 15/10, 13/10, 15/9, 14/11, 12/9) with rain codes; sunrise 06:38, sunset 17:06.

- [ ] **Step 1: Failing tests**
```swift
@Test func wmoMapping() {
  #expect(WeatherCondition(wmoCode: 3) == .cloudy && WeatherCondition(wmoCode: 3).text == "Cloudy")
  #expect(WeatherCondition(wmoCode: 65) == .heavyRain)
  #expect(WeatherCondition(wmoCode: 999) == .cloudy)
  #expect(WeatherCondition(wmoCode: 75).isSnow)
}
@Test func temperatureFormatting() {
  #expect(TemperatureUnit.celsius.format(13.4) == "13°")
  #expect(TemperatureUnit.celsius.format(-0.4) == "0°")
  #expect(TemperatureUnit.celsius.format(-3.6) == "-4°")
  #expect(TemperatureUnit.fahrenheit.format(13) == "55°")
}
@Test func compass() { #expect(WindUnit.compass(315) == "NW"); #expect(WindUnit.compass(350) == "N") }
@Test func hoursStartAtCurrentHour() {
  // snapshot hourly starts 00:00; now = 05:20 same day → first hour 05:00, count 18
  let s = WeatherSnapshot.make(hourlyStart: midnight, count: 48)   // test helper in test file
  let h = s.hours(from: midnight.addingTimeInterval(5*3600 + 20*60), count: 18)
  #expect(h.count == 18 && h.first!.time == midnight.addingTimeInterval(5*3600))
}
@Test func coordinateNear() {
  #expect(Coordinate(latitude: 42.70, longitude: 23.32).isNear(.init(latitude: 42.705, longitude: 23.321)))
  #expect(!Coordinate(latitude: 42.70, longitude: 23.32).isNear(.init(latitude: 42.75, longitude: 23.32)))
}
```
- [ ] **Step 2:** `swift test` → FAIL (types missing).
- [ ] **Step 3:** Implement the types above.
- [ ] **Step 4:** `swift test` → PASS.
- [ ] **Step 5:** Commit `feat(core): weather model, WMO conditions, formatting`.

### Task 4: Open-Meteo client

**Files:** Create `Weather/OpenMeteoClient.swift`; Test `OpenMeteoClientTests.swift`, `Fixtures/forecast.json`, `Fixtures/geocoding.json`

**Interfaces:**
- Consumes: Task 3 types.
- Produces: `public protocol WeatherFetching: Sendable { func fetch(for location: SavedLocation) async throws -> WeatherSnapshot }`; `public struct OpenMeteoClient: WeatherFetching { init(session: URLSession = .shared); func searchCities(_ query: String) async throws -> [SavedLocation] }`; internal `static func forecastURL(for: Coordinate) -> URL`, `static func decodeForecast(_ data: Data, location: SavedLocation, fetchedAt: Date) throws -> WeatherSnapshot`, `static func decodeCities(_ data: Data) throws -> [SavedLocation]`.

Forecast URL (exact query items):
`https://api.open-meteo.com/v1/forecast?latitude=…&longitude=…&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,uv_index,wind_speed_10m,wind_direction_10m&hourly=temperature_2m,precipitation_probability,precipitation,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset&timezone=auto&forecast_days=7`
Geocoding: `https://geocoding-api.open-meteo.com/v1/search?name=…&count=10&language=en&format=json` → `results[].{name, latitude, longitude, country, admin1, timezone}`; `SavedLocation.name` = `name`; empty/absent `results` → `[]`.

Times are local strings `yyyy-MM-dd'T'HH:mm` (daily `date`: `yyyy-MM-dd`) in the location's zone: parse with `TimeZone(secondsFromGMT: utc_offset_seconds)`.

- [ ] **Step 1:** Write `forecast.json` fixture by hand (trimmed real shape): `utc_offset_seconds: 32400` (Tokyo), `timezone: "Asia/Tokyo"`, current temp 13.2, code 3; hourly 3 entries starting `2026-11-16T00:00`; daily 2 entries, first sunrise `2026-11-16T06:20`. `geocoding.json` with one Sofia result and a second file-less case of `{}`.
- [ ] **Step 2: Failing tests**
```swift
@Test func decodesForecastInLocationTimeZone() throws {
  let s = try OpenMeteoClient.decodeForecast(fixture("forecast"), location: tokyo, fetchedAt: .now)
  #expect(s.current.temperature == 13.2 && s.current.condition == .cloudy)
  #expect(s.hourly.first!.time == iso("2026-11-15T15:00:00Z"))   // 00:00 JST
  #expect(s.daily.first!.sunrise == iso("2026-11-15T21:20:00Z"))
}
@Test func forecastURLHasRequiredParams() {
  let q = URLComponents(url: OpenMeteoClient.forecastURL(for: sofia.coordinate), resolvingAgainstBaseURL: false)!.queryItems!
  #expect(q.contains(.init(name: "timezone", value: "auto")))
  #expect(q.first { $0.name == "daily" }!.value!.contains("sunrise"))
}
@Test func decodesCities() throws {
  #expect(try OpenMeteoClient.decodeCities(fixture("geocoding")).first?.name == "Sofia")
  #expect(try OpenMeteoClient.decodeCities(Data("{}".utf8)).isEmpty)
}
```
- [ ] **Step 3:** `swift test` → FAIL. Implement. `swift test` → PASS.
- [ ] **Step 4:** One live sanity run (not a unit test): `curl` the forecast URL for 42.70,23.32 and confirm `decodeForecast` accepts it (temporary `swift test --filter` with env var `LIVE=1`, skipped otherwise).
- [ ] **Step 5:** Commit `feat(core): Open-Meteo forecast and geocoding client`.

### Task 5: Settings + WeatherStore

**Files:** Create `Settings/SettingsStore.swift`, `Weather/WeatherStore.swift`; Test `SettingsStoreTests.swift`, `WeatherStoreTests.swift`

**Interfaces:**
- `public enum LocationMode: Codable { case current, manual }`
- `public final class SettingsStore: Sendable` (wraps `UserDefaults`, init `(defaults: UserDefaults = AppGroup.defaults)`), properties get/set: `locationMode`, `currentLocation: SavedLocation?` (last GPS fix), `manualLocation: SavedLocation?`, `var activeLocation: SavedLocation?` (per mode), `temperatureUnit` (default `.celsius`), `windUnit` (`.kmh`), `uses24HourClock` (`true`), `worldClocks: [WorldClock]` (default London/New York/Tokyo; setter truncates to 3). `public struct WorldClock: Codable, Sendable, Equatable { name: String; timeZoneID: String }`.
- `public enum WeatherError: Error { case noLocation }`
- `public struct WeatherResult: Sendable { snapshot: WeatherSnapshot; isStale: Bool }`
- `public actor WeatherStore { init(fetcher: WeatherFetching, settings: SettingsStore, cacheURL: URL = AppGroup.containerURL.appending(path: "weather.json"), now: @Sendable () -> Date = Date.init); func load(forceRefresh: Bool = false) async throws -> WeatherResult }`
  - No `activeLocation` → throw `.noLocation`.
  - Cache valid iff age < 30 min **and** `cache.location.coordinate.isNear(active.coordinate)`.
  - Fetch failure + cache for same location → cached with `isStale: true`; otherwise rethrow.

- [ ] **Step 1: Failing tests** (fake fetcher counts calls; temp dir cache; `UserDefaults(suiteName: UUID().uuidString)`):
  - `defaultsAreSensible`: celsius, kmh, 24h true, worldClocks names `["London","New York","Tokyo"]`.
  - `worldClocksCappedAtThree`: set 4 → count 3.
  - `activeLocationFollowsMode`: manual mode returns manual location.
  - `noLocationThrows`: `#expect(throws: WeatherError.noLocation)`.
  - `freshCacheSkipsFetch`: fetch at t0, load at t0+29 min → fetcher calls == 1.
  - `expiredCacheRefetches`: t0+31 min → calls == 2.
  - `locationChangeRefetches`: switch manual location Sofia → Tokyo at t0+1 min → calls == 2 and result location name "Tokyo".
  - `failureServesStale`: fetcher throws after first → `isStale == true`.
  - `failureWithoutCacheThrows`.
- [ ] **Step 2:** `swift test` → FAIL. Implement. `swift test` → PASS.
- [ ] **Step 3:** Commit `feat(core): settings store and cached weather store`.

### Task 6: Astronomy + summary sentence

**Files:** Create `Astronomy/MoonPhase.swift`, `Astronomy/SunTimes.swift`, `Text/WeatherSummary.swift`; Test `AstronomyTests.swift`, `SummaryTests.swift`

**Interfaces:**
- `public struct MoonPhase { init(date: Date); age: Double /*days*/; fraction: Double /*0..<1*/; illumination: Double; name: Name }`, `enum Name: String { newMoon "New moon", waxingCrescent "Waxing crescent", firstQuarter "First quarter", waxingGibbous "Waxing gibbous", fullMoon "Full moon", waningGibbous "Waning gibbous", lastQuarter "Last quarter", waningCrescent "Waning crescent" }`.
  Algorithm: reference new moon `2000-01-06T18:14:00Z`, synodic month `29.530588853` d; `fraction = age/P`; `illumination = (1 − cos 2π·fraction)/2`. Name by fraction: `<0.0339 | ≥0.9661` new; `<0.2161` waxing crescent; `<0.2839` first quarter; `<0.4661` waxing gibbous; `<0.5339` full; `<0.7161` waning gibbous; `<0.7839` last quarter; else waning crescent.
- `public enum SunTimes { static func goldenHour(sunset: Date) -> Date /* −40 min */; static func progress(now: Date, sunrise: Date, sunset: Date) -> Double? /* nil when outside daylight, else 0…1 */ }`
- `public enum WeatherSummary { static func sentence(for: WeatherSnapshot, now: Date, unit: TemperatureUnit) -> String }`. Rules:
  1. Next 18 h (`hours(from: now, count: 18)`): word = "Snow" if that hour's condition `isSnow` else "Rain". First hour with probability ≥ 50: if it's the current hour → "\(word) likely now." else "\(word) likely from HH:mm." (24h, location tz). Else if max probability ≥ 30 → "Chance of \(word.lowercased()) later." Else "No rain in the next 18 hours."
  2. Tomorrow (`days(after: now, count: 1)`): "Tomorrow \(unit.format(max))" + (precip ≥ 50 → ", rain likely." / ", snow likely." for snow condition) else (max − today.max ≥ 3 → ", warmer.") else (≤ −3 → ", cooler.") else ".".
  Joined with a space.

- [ ] **Step 1: Failing tests**
```swift
@Test func waningGibbousOnReferenceDate() { #expect(MoonPhase(date: iso("2026-10-28T12:00:00Z")).name == .waningGibbous) }
@Test func fullMoon() { let m = MoonPhase(date: iso("2026-10-26T04:12:00Z")); #expect(m.name == .fullMoon && m.illumination > 0.99) }
@Test func newMoon() { #expect(MoonPhase(date: iso("2026-11-09T07:02:00Z")).name == .newMoon) }
@Test func goldenHour() { #expect(SunTimes.goldenHour(sunset: t("17:06")) == t("16:26")) }
@Test func sunProgress() { #expect(SunTimes.progress(now: t("11:52"), sunrise: t("06:38"), sunset: t("17:06")) == 0.5); #expect(SunTimes.progress(now: t("20:00"), sunrise: t("06:38"), sunset: t("17:06")) == nil) }
@Test func referenceSentence() { // dry 18h, tomorrow max 15, precip 80
  #expect(WeatherSummary.sentence(for: dryToday_rainyTomorrow, now: now, unit: .celsius) == "No rain in the next 18 hours. Tomorrow 15°, rain likely.") }
@Test func rainFromHour() { #expect(WeatherSummary.sentence(for: rainAt15, now: at("09:10"), unit: .celsius).hasPrefix("Rain likely from 15:00.")) }
@Test func rainNow() { #expect(...hasPrefix("Rain likely now.")) }
@Test func snowWording() { #expect(...hasPrefix("Snow likely from")) }
@Test func warmer() { #expect(...hasSuffix("Tomorrow 18°, warmer.")) }
```
- [ ] **Step 2:** `swift test` → FAIL. Implement. `swift test` → PASS.
- [ ] **Step 3:** Commit `feat(core): moon phase, sun times, summary sentence`.

### Task 7: Design catalog + filtering

**Files:** Create `Registry/DesignCatalog.swift`; Test `DesignCatalogTests.swift`

**Interfaces:**
- `public enum WidgetCategory: String, CaseIterable { clock, weather, sunMoon }` with `title` ("Clock", "Weather", "Sun & Moon").
- `public enum WidgetStyle: String, CaseIterable { editorial }` with `title` ("Editorial").
- `public enum WidgetSize: String, CaseIterable, Comparable { small, medium, large }` with `title`, `previewSize: CGSize` (170×170, 364×170, 364×382).
- `public struct DesignInfo: Identifiable, Hashable { id: String; name: String; category; style; sizes: [WidgetSize]; summary: String }`
- `public struct DesignCard: Identifiable, Hashable { design: DesignInfo; size: WidgetSize; id: "\(design.id).\(size)" }`
- `public enum DesignCatalog { static let all: [DesignInfo]; static func cards(size: WidgetSize? = nil, category: WidgetCategory? = nil, style: WidgetStyle? = nil, query: String = "") -> [DesignCard] }` — AND filters; query trimmed, case-insensitive, matches design name or category title; order = catalog order then size order.
- Catalog: `editorial.weather` "Editorial Weather" [S,M,L]; `editorial.clock` "Editorial Clock" [S,M,L]; `editorial.sunmoon` "Editorial Sun & Moon" [S]. Summaries: one sentence each.

- [ ] **Step 1: Failing tests:** all → 7 cards; `size: .large` → 2; `category: .weather, size: .small` → ids `["editorial.weather.small"]`; `query: "  MOON "` → 1; `query: "zzz"` → 0; `style: .editorial` → 7.
- [ ] **Step 2:** FAIL → implement → PASS.
- [ ] **Step 3:** Commit `feat(core): design catalog with size/category/style filters`.

### Task 8: Editorial theme + components

**Files:** Create `BorneDesigns/Entries.swift`, `Styles/Editorial/Theme.swift`, `Styles/Editorial/Components/{ContourBackground,FrameBorder,StatLabel,TemperatureCurve,ForecastStrip,SunArc,MoonGlyph,AnalogFace}.swift`, `Styles/Editorial/EmptyStateView.swift`

**Interfaces:**
- `public struct WeatherEntry: TimelineEntry { date: Date; state: State; temperatureUnit: TemperatureUnit; windUnit: WindUnit }`, `enum State { case loaded(WeatherSnapshot, isStale: Bool), noLocation, unavailable }`, `static let sample`.
- `public struct ClockEntry: TimelineEntry { date: Date; uses24Hour: Bool; worldClocks: [WorldClock]; static let sample }`
- `enum EditorialTheme` tokens: background `#141A24`, contour lines `white @ 4%`, primary `#F2EFE8`, secondary `#8C919A`, rain `#6FA8DC`, golden `#E8915A`, border gold `#B8975A` 1pt inset 4pt; `numeral(size:)` → `.system(size:, weight: .regular, design: .serif)`, `italic(size:)` serif italic, `label(size:)` → `.system(size:, weight: .medium, design: .monospaced).smallCaps()` with 1pt tracking.
- Components (each `View`, takes model values, no data loading): `ContourBackground` (Canvas, deterministic wavy contours), `FrameBorder`, `StatLabel(title:value:valueColor:)`, `TemperatureCurve(hours:[Hour], unit:, now:)` (smooth line, hatched fill under segments where probability ≥ 50, labels at start/max/end, time ticks every 4 h), `ForecastStrip(days:, unit:)` (day abbr, symbol, max, vertical min–max range bar scaled across week, min), `SunArc(sunrise:, sunset:, now:, timeZone:)` (dashed half-ellipse, orange "Now" dot from `SunTimes.progress`, times in location tz), `MoonGlyph(phase: MoonPhase)` (lit portion drawn from `fraction`), `AnalogFace(date:, showsNumerals:)`.
- Rendering mode: components read `@Environment(\.widgetRenderingMode)`; in `.accented` drop ContourBackground, hatch and color accents become `.primary`; numerals get `.widgetAccentable()`.
- `EmptyStateView(message:)` — serif italic message on theme background.

- [ ] **Step 1:** Implement; each component file has a `#Preview` on theme background with `WeatherSnapshot.sample` values.
- [ ] **Step 2:** Build `BorneDesigns` for iOS: `xcodebuild -scheme BorneDesigns -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3' build` (run in `BorneKit/`) → BUILD SUCCEEDED; `swift test` still PASS.
- [ ] **Step 3:** Commit `feat(designs): editorial theme and components`.

### Task 9: Editorial widget views + registry views

**Files:** Create `Styles/Editorial/Weather/EditorialWeather{Small,Medium,Large}.swift`, `Styles/Editorial/Clock/EditorialClock{Small,Medium,Large}.swift`, `Styles/Editorial/SunMoon/EditorialSunMoonSmall.swift`, `BorneDesigns/DesignRegistry.swift`

**Interfaces:**
- `public enum DesignRegistry { @MainActor @ViewBuilder static func view(for card: DesignCard, weather: WeatherEntry, clock: ClockEntry) -> some View }` — switches on design id + size; used by app previews and widgets alike.
- `extension WidgetSize { var family: WidgetFamily; init?(_ family: WidgetFamily) }`
- Each weather/sun-moon view takes `WeatherEntry`; `.noLocation` → `EmptyStateView("Open Borne to set a location")`; `.unavailable` → `EmptyStateView("Weather unavailable")`; stale → tiny "updated HH:mm" label in secondary color.
- Layouts per spec table. Large weather mirrors reference: header (temp numeral ~64pt, italic condition, RAIN/HUMID/UV labels, wind compass top-right), FEELS/HIGH/LOW row, "NEXT 18 HOURS · HATCHED = RAIN" + `TemperatureCurve`, `ForecastStrip` (6 days), `SunArc` + `MoonGlyph` + phase name + "GOLDEN hh:mm", italic `WeatherSummary` sentence, location (small caps) + full date (small caps).
- Clock large: `ClockEntry.worldClocks`, each row: city small caps, serif time in that tz, offset from local ("+9h"), `sun.max`/`moon` symbol for 06–18 local.

- [ ] **Step 1:** Implement all 7 views with `#Preview(as: .systemX)` timelines using samples (weather loaded, stale, noLocation).
- [ ] **Step 2:** Package iOS build → BUILD SUCCEEDED. Visually inspect previews (render via `xcodebuild` + simulator in Task 10 if previews unavailable headless).
- [ ] **Step 3:** Commit `feat(designs): editorial weather, clock, sun & moon views`.

### Task 10: Widget extension

**Files:** Create `WidgetExtension/Providers/{WeatherProvider,ClockProvider}.swift`, `WidgetExtension/Widgets/{EditorialWeatherWidget,EditorialClockWidget,EditorialSunMoonWidget}.swift`; Modify `WidgetExtension/BorneWidgetBundle.swift` (drop placeholder)

**Interfaces:**
- `WeatherProvider: TimelineProvider` — `placeholder`/`getSnapshot` (when `context.isPreview`) → `WeatherEntry.sample`; `getTimeline` → `WeatherStore(fetcher: OpenMeteoClient(), settings: SettingsStore()).load()`; map `.noLocation` → `.noLocation`, other errors → `.unavailable`; policy `.after(now + 30 min)`.
- `ClockProvider` — 60 entries one per minute from the start of the current minute, `.atEnd`; reads `uses24HourClock`, `worldClocks`.
- Each `Widget`: `kind` = design id, `StaticConfiguration`, `configurationDisplayName` = design name, `description` = summary, `supportedFamilies` = design sizes mapped to families, body = `DesignRegistry.view(...)` wrapped with `.containerBackground(for: .widget) { EditorialTheme.background }`; `.contentMarginsDisabled()` where the design draws its own frame.

- [ ] **Step 1:** Implement; build app scheme for simulator → BUILD SUCCEEDED.
- [ ] **Step 2:** Install on iPhone 17 (26.3) simulator, `xcrun simctl location booted set 42.6977,23.3219`. (No location saved yet → expect "Open Borne to set a location" on weather widgets.) Add each of the 7 widget sizes to the home screen; screenshot with `xcrun simctl io booted screenshot`. Check: clock ticks over the minute; previews in gallery look right; switch home screen to tinted mode and confirm legibility.
- [ ] **Step 3:** Commit `feat(widgets): weather, clock and sun & moon widgets`.

### Task 11: App — location + settings

**Files:** Create `App/Location/LocationService.swift`, `App/Settings/{SettingsView,CitySearchView,WorldClocksEditor}.swift`, `App/AppModel.swift`

**Interfaces:**
- `@MainActor @Observable final class AppModel { settings: SettingsStore; weather: WeatherEntry; clock: ClockEntry; func refresh(force: Bool) async }` — after any settings change or successful fetch call `WidgetCenter.shared.reloadAllTimelines()`.
- `@MainActor final class LocationService: NSObject, CLLocationManagerDelegate { func requestCurrentLocation() async throws -> SavedLocation }` — When-In-Use; reverse geocode with MapKit `MKReverseGeocodingRequest` (CLGeocoder is deprecated in iOS 26), name = locality, fallback "Current location"; time zone from result or `TimeZone.current`.
- Settings (`Form` in `NavigationStack`, system glass toolbar): Location section (Current / Manual picker; "Use current location" button; "Search city" → `CitySearchView` using `OpenMeteoClient.searchCities` with `.searchable`, debounced 300 ms); Units (temperature, wind); Clock (24-hour toggle, world clocks editor with up to 3, reorder/delete, add via city search reusing `timezone`); "Refresh weather now" (`.buttonStyle(.glassProminent)`); footer "Weather data by Open-Meteo.com" linking `https://open-meteo.com`.
- Permission denied → inline note offering manual city.

- [ ] **Step 1:** Implement; build → BUILD SUCCEEDED.
- [ ] **Step 2:** Simulator: grant location (simctl location set Sofia) → settings shows "Sofia"; weather widgets update after reload. Search "Tokyo", pick it → widgets show Tokyo with Tokyo-local sunrise. Deny permission (`xcrun simctl privacy booted revoke location dev.borne.bornewidgets`) → note shown, manual search still works.
- [ ] **Step 3:** Commit `feat(app): location, city search and settings`.

### Task 12: App — Liquid Glass library, search, detail

**Files:** Create `App/RootView.swift`, `App/Library/{LibraryView,FilterBar,PreviewCard}.swift`, `App/Detail/DesignDetailView.swift`; Modify `App/BorneWidgetsApp.swift`

**Interfaces:**
- `RootView`: `TabView` with `Tab("Library", systemImage: "square.grid.2x2")`, `Tab("Settings", systemImage: "gearshape")`, `Tab(role: .search)` hosting `LibraryView(searchMode: true)`; `.tabBarMinimizeBehavior(.onScrollDown)`.
- `LibraryView`: `NavigationStack`; `ScrollView` grid of `PreviewCard`s from `DesignCatalog.cards(size:category:style:query:)` — smalls pair two-up, medium/large full width; `FilterBar` attached via `.safeAreaBar(edge: .top)` so content scrolls under it; empty result → `ContentUnavailableView`. Backdrop: deep tonal gradient via asset colors (light + dark variants), not glass.
- `FilterBar`: three chip rows (Size, Category, Style — Style row hidden while `WidgetStyle.allCases.count == 1`) inside `GlassEffectContainer(spacing: 8)`; each chip `Button` with `.glassEffect(selected ? .regular.tint(.accentColor).interactive() : .regular.interactive(), in: .capsule)` and `.glassEffectID(chip.id, in: namespace)`; selection change wrapped in `withAnimation(.bouncy)`.
- `PreviewCard`: `DesignRegistry.view(for:weather:clock:)` at `size.previewSize`, `RoundedRectangle(cornerRadius: 22)` clip (continuous), shadow; caption below (design name, size) — no glass on card. Tap → `DesignDetailView`.
- `DesignDetailView`: all sizes of the design stacked, summary, "How to add" sheet (`.buttonStyle(.glassProminent)`): 1) Touch and hold the Home Screen 2) Tap Edit → Add Widget 3) Search "Borne" 4) Pick "\(design.name)" and size.

- [ ] **Step 1:** Implement; build → BUILD SUCCEEDED.
- [ ] **Step 2:** Simulator check on iPhone 17 (26.3) and iPhone 18 Pro (27.0), light + dark: filters combine (Large + Weather → 1 card); chips morph on select; grid scrolls under glass filter bar; tab bar minimizes on scroll; search "moon" → Sun & Moon only; Settings → Accessibility → Reduce Transparency on → chrome stays legible. Screenshots saved to scratch for README.
- [ ] **Step 3:** Commit `feat(app): liquid glass widget library with filters and detail`.

### Task 13: README, license, final verification

**Files:** Create `README.md`, `LICENSE` (MIT, holder "Borne Widgets contributors"), `docs/screenshots/*.png`

- [ ] **Step 1:** README: one-paragraph intro, screenshots, requirements (Xcode 27+, iOS 26+), build (`brew install xcodegen`, `xcodegen`, open project, run), device build (`cp Config/Local.xcconfig.example Config/Local.xcconfig`, set team + bundle prefix), architecture sketch (targets, BorneCore/BorneDesigns, Styles/<Style>), "Adding a style" steps (new `WidgetStyle` case, folder under `Styles/`, catalog entries, registry cases, `Widget` structs), attribution "Weather data by Open-Meteo.com".
- [ ] **Step 2:** Full verification: `cd BorneKit && swift test` → all PASS; `xcodegen && xcodebuild ... build` for both simulators → BUILD SUCCEEDED; fresh-clone check: `git clone` the repo into the session scratchpad directory, `xcodegen`, build succeeds with no Local.xcconfig.
- [ ] **Step 3:** Commit `docs: README, license, screenshots`.
