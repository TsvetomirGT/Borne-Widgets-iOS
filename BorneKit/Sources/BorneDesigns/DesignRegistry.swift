import BorneCore
import SwiftUI
import WidgetKit

/// Maps catalog designs to their SwiftUI views. Both the app's previews and
/// the widget extension render through here, so they always match.
public enum DesignRegistry {
    @MainActor @ViewBuilder
    public static func view(
        for card: DesignCard,
        weather: WeatherEntry,
        clock: ClockEntry,
        calendar: CalendarEntry = .sample,
        drawsBackground: Bool = true
    ) -> some View {
        EditorialCanvas(drawsBackground: drawsBackground) {
            content(for: card, weather: weather, clock: clock, calendar: calendar)
        }
    }

    /// Background a widget hands to `containerBackground(for: .widget)`.
    @MainActor @ViewBuilder
    public static func background(for design: DesignInfo) -> some View {
        switch design.style {
        case .editorial: ContourBackground()
        }
    }

    @MainActor @ViewBuilder
    private static func content(for card: DesignCard, weather: WeatherEntry, clock: ClockEntry,
                                calendar: CalendarEntry) -> some View {
        switch (card.design.id, card.size) {
        case ("editorial.weather", .small): EditorialWeatherSmall(entry: weather)
        case ("editorial.weather", .medium): EditorialWeatherMedium(entry: weather)
        case ("editorial.weather", .large): EditorialWeatherLarge(entry: weather)
        case ("editorial.weather", .extraLarge): EditorialWeatherExtraLarge(entry: weather)
        case ("editorial.clock", .small): EditorialClockSmall(entry: clock)
        case ("editorial.clock", .medium): EditorialClockMedium(entry: clock)
        case ("editorial.clock", .large): EditorialClockLarge(entry: clock)
        case ("editorial.sunmoon", _): EditorialSunMoonSmall(entry: weather)
        case ("editorial.calendar", .small): EditorialCalendarSmall(entry: calendar)
        case ("editorial.calendar", .medium): EditorialCalendarMedium(entry: calendar)
        case ("editorial.calendar", .large): EditorialCalendarLarge(entry: calendar)
        case ("editorial.calendar", .extraLarge): EditorialCalendarExtraLarge(entry: calendar)
        default: EditorialEmptyState(message: "Unknown design", symbol: "questionmark")
        }
    }
}

extension WidgetSize {
    /// The WidgetKit family, or nil when this OS doesn't offer the size
    /// (the full-page portrait widget needs iOS 27).
    public var family: WidgetFamily? {
        switch self {
        case .small: .systemSmall
        case .medium: .systemMedium
        case .large: .systemLarge
        case .extraLarge:
            if #available(iOS 27.0, macOS 27.0, *) { .systemExtraLargePortrait } else { nil }
        }
    }

    public init?(_ family: WidgetFamily) {
        if #available(iOS 27.0, macOS 27.0, *), family == .systemExtraLargePortrait {
            self = .extraLarge
            return
        }
        switch family {
        case .systemSmall: self = .small
        case .systemMedium: self = .medium
        case .systemLarge: self = .large
        default: return nil
        }
    }

    /// Families to declare for a design on this OS.
    public static func families(for sizes: [WidgetSize]) -> [WidgetFamily] {
        sizes.compactMap(\.family)
    }
}

// MARK: - Previews

#Preview("Weather · large", traits: .fixedLayout(width: 364, height: 382)) {
    DesignRegistry.view(for: DesignCard(design: DesignCatalog.editorialWeather, size: .large),
                        weather: .sample, clock: .sample)
        .containerShape(RoundedRectangle(cornerRadius: 22))
}

#Preview("Weather · medium", traits: .fixedLayout(width: 364, height: 170)) {
    DesignRegistry.view(for: DesignCard(design: DesignCatalog.editorialWeather, size: .medium),
                        weather: .sample, clock: .sample)
        .containerShape(RoundedRectangle(cornerRadius: 22))
}

#Preview("Clock · large", traits: .fixedLayout(width: 364, height: 382)) {
    DesignRegistry.view(for: DesignCard(design: DesignCatalog.editorialClock, size: .large),
                        weather: .sample, clock: .sample)
        .containerShape(RoundedRectangle(cornerRadius: 22))
}
