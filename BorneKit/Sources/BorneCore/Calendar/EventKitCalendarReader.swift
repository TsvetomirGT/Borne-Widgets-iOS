import CoreGraphics
import EventKit
import Foundation

/// Reads events for the calendar widgets.
public protocol CalendarReading: Sendable {
    var access: CalendarAccess { get }
    func events(from start: Date, to end: Date) -> [CalendarEvent]
}

/// EventKit-backed reader. The widget extension uses the containing app's
/// Calendar permission, so the app asks once and both can read.
/// Event data is only read, never stored or sent anywhere.
public struct EventKitCalendarReader: CalendarReading {
    public init() {}

    public var access: CalendarAccess {
        Self.access(for: EKEventStore.authorizationStatus(for: .event))
    }

    public func events(from start: Date, to end: Date) -> [CalendarEvent] {
        guard access == .granted else { return [] }
        let store = EKEventStore()
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map { e in
            CalendarEvent(id: e.calendarItemIdentifier + "@" + String(e.startDate.timeIntervalSince1970),
                          title: e.title ?? "",
                          start: e.startDate, end: e.endDate, isAllDay: e.isAllDay,
                          color: Self.rgb(e.calendar?.cgColor))
        }
    }

    /// Asks for full access (needed to read events). Returns the new state.
    public static func requestAccess() async -> CalendarAccess {
        _ = try? await EKEventStore().requestFullAccessToEvents()
        return access(for: EKEventStore.authorizationStatus(for: .event))
    }

    static func access(for status: EKAuthorizationStatus) -> CalendarAccess {
        switch status {
        case .fullAccess: .granted
        case .notDetermined: .notDetermined
        default: .denied
        }
    }

    static func rgb(_ color: CGColor?) -> RGB {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let c = color?.converted(to: srgb, intent: .defaultIntent, options: nil),
              let parts = c.components, parts.count >= 3
        else { return RGB(red: 0.5, green: 0.5, blue: 0.5) }
        return RGB(red: parts[0], green: parts[1], blue: parts[2])
    }
}
