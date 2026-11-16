import CoreGraphics
import Foundation

public enum WidgetCategory: String, CaseIterable, Sendable, Identifiable {
    case clock, weather, sunMoon, calendar
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .clock: "Clock"
        case .weather: "Weather"
        case .sunMoon: "Sun & Moon"
        case .calendar: "Calendar"
        }
    }
}

public enum WidgetStyle: String, CaseIterable, Sendable, Identifiable {
    case editorial
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .editorial: "Editorial"
        }
    }
}

public enum WidgetSize: String, CaseIterable, Sendable, Identifiable, Comparable {
    case small, medium, large
    /// iOS 27's full-page portrait widget (`systemExtraLargePortrait`).
    case extraLarge
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra Large"
        }
    }

    /// Home-screen widget size on a 6.3" iPhone, used for in-app previews.
    public var previewSize: CGSize {
        switch self {
        case .small: CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 364, height: 170)
        case .large: CGSize(width: 364, height: 382)
        case .extraLarge: CGSize(width: 364, height: 592)
        }
    }

    public static func < (a: Self, b: Self) -> Bool {
        allCases.firstIndex(of: a)! < allCases.firstIndex(of: b)!
    }
}

/// A widget design: one category in one style, available in some sizes.
/// Its `id` is also the WidgetKit `kind`.
public struct DesignInfo: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: WidgetCategory
    public let style: WidgetStyle
    public let sizes: [WidgetSize]
    public let summary: String
}

/// One design rendered at one size — a tile in the library.
public struct DesignCard: Identifiable, Hashable, Sendable {
    public let design: DesignInfo
    public let size: WidgetSize
    public var id: String { "\(design.id).\(size.rawValue)" }

    public init(design: DesignInfo, size: WidgetSize) {
        self.design = design
        self.size = size
    }
}

public enum DesignCatalog {
    public static let editorialWeather = DesignInfo(
        id: "editorial.weather", name: "Editorial Weather", category: .weather, style: .editorial,
        sizes: [.small, .medium, .large, .extraLarge],
        summary: "Serif numerals, an 18-hour temperature curve and the week ahead, set like a printed almanac."
    )
    public static let editorialClock = DesignInfo(
        id: "editorial.clock", name: "Editorial Clock", category: .clock, style: .editorial,
        sizes: [.small, .medium, .large],
        summary: "A hairline analog face, a typeset digital time, and world clocks for the places you care about."
    )
    public static let editorialSunMoon = DesignInfo(
        id: "editorial.sunmoon", name: "Editorial Sun & Moon", category: .sunMoon, style: .editorial,
        sizes: [.small],
        summary: "The sun's arc from sunrise to sunset, beside tonight's moon phase."
    )

    public static let editorialCalendar = DesignInfo(
        id: "editorial.calendar", name: "Editorial Calendar", category: .calendar, style: .editorial,
        sizes: [.small, .medium, .large, .extraLarge],
        summary: "Today's date set large, the month in a quiet grid, and what's coming up from your calendars."
    )

    public static let all: [DesignInfo] = [editorialWeather, editorialClock, editorialSunMoon, editorialCalendar]

    public static func design(id: String) -> DesignInfo? { all.first { $0.id == id } }

    public static func cards(
        size: WidgetSize? = nil,
        category: WidgetCategory? = nil,
        style: WidgetStyle? = nil,
        query: String = ""
    ) -> [DesignCard] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return all
            .filter { category == nil || $0.category == category }
            .filter { style == nil || $0.style == style }
            .filter {
                q.isEmpty
                    || $0.name.localizedCaseInsensitiveContains(q)
                    || $0.category.title.localizedCaseInsensitiveContains(q)
            }
            .flatMap { design in
                design.sizes
                    .filter { size == nil || $0 == size }
                    .map { DesignCard(design: design, size: $0) }
            }
    }
}
