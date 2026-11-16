import Foundation
import Testing
@testable import BorneCore

private func t(_ hhmm: String) -> Date { iso("2026-11-16T\(hhmm):00Z") }

@Test func waningGibbousOnReferenceDate() {
    #expect(MoonPhase(date: iso("2026-10-28T12:00:00Z")).name == .waningGibbous)
}

@Test func fullMoon() {
    let m = MoonPhase(date: iso("2026-10-26T04:12:00Z"))
    #expect(m.name == .fullMoon)
    #expect(m.illumination > 0.99)
}

@Test func newMoon() {
    let m = MoonPhase(date: iso("2026-11-09T07:02:00Z"))
    #expect(m.name == .newMoon)
    #expect(m.illumination < 0.01)
}

@Test func phaseBeforeReferenceEpochIsValid() {
    let m = MoonPhase(date: iso("1999-07-28T11:25:00Z"))   // full moon
    #expect((0..<1).contains(m.fraction))
    #expect(m.name == .fullMoon)
}

@Test func phaseNameText() {
    #expect(MoonPhase.Name.waningGibbous.rawValue == "Waning gibbous")
}

@Test func goldenHour() {
    #expect(SunTimes.goldenHour(sunset: t("17:06")) == t("16:26"))
}

@Test func sunProgress() {
    #expect(SunTimes.progress(now: t("11:52"), sunrise: t("06:38"), sunset: t("17:06")) == 0.5)
    #expect(SunTimes.progress(now: t("06:38"), sunrise: t("06:38"), sunset: t("17:06")) == 0)
    #expect(SunTimes.progress(now: t("20:00"), sunrise: t("06:38"), sunset: t("17:06")) == nil)
    #expect(SunTimes.progress(now: t("05:00"), sunrise: t("06:38"), sunset: t("17:06")) == nil)
}
