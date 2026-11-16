import Foundation
import Testing
@testable import BorneCore

func freshDefaults() -> UserDefaults {
    UserDefaults(suiteName: "borne.tests.\(UUID().uuidString)")!
}

@Test func defaultsAreSensible() {
    let s = SettingsStore(defaults: freshDefaults())
    #expect(s.temperatureUnit == .celsius)
    #expect(s.windUnit == .kmh)
    #expect(s.uses24HourClock)
    #expect(s.locationMode == .current)
    #expect(s.activeLocation == nil)
    #expect(s.worldClocks.map(\.name) == ["London", "New York", "Tokyo"])
    #expect(s.worldClocks.map(\.timeZoneID) == ["Europe/London", "America/New_York", "Asia/Tokyo"])
}

@Test func settingsPersistAcrossInstances() {
    let d = freshDefaults()
    let a = SettingsStore(defaults: d)
    a.temperatureUnit = .fahrenheit
    a.uses24HourClock = false
    a.manualLocation = tokyo
    let b = SettingsStore(defaults: d)
    #expect(b.temperatureUnit == .fahrenheit)
    #expect(!b.uses24HourClock)
    #expect(b.manualLocation == tokyo)
}

@Test func worldClocksCappedAtThree() {
    let s = SettingsStore(defaults: freshDefaults())
    s.worldClocks = (1...4).map { WorldClock(name: "C\($0)", timeZoneID: "UTC") }
    #expect(s.worldClocks.count == 3)
}

@Test func activeLocationFollowsMode() {
    let s = SettingsStore(defaults: freshDefaults())
    s.currentLocation = sofia
    s.manualLocation = tokyo
    #expect(s.activeLocation == sofia)
    s.locationMode = .manual
    #expect(s.activeLocation == tokyo)
}
