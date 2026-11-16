import EventKit
import Testing
@testable import BorneCore

@Test func accessMapping() {
    #expect(EventKitCalendarReader.access(for: .fullAccess) == .granted)
    #expect(EventKitCalendarReader.access(for: .writeOnly) == .denied)
    #expect(EventKitCalendarReader.access(for: .denied) == .denied)
    #expect(EventKitCalendarReader.access(for: .restricted) == .denied)
    #expect(EventKitCalendarReader.access(for: .notDetermined) == .notDetermined)
}
