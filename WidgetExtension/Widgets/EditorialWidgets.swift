import BorneCore
import BorneDesigns
import SwiftUI
import WidgetKit

struct EditorialWeatherWidget: Widget {
    let design = DesignCatalog.editorialWeather

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: design.id, provider: WeatherProvider()) { entry in
            DesignWidgetView(design: design, weather: entry)
        }
        .configurationDisplayName(design.name)
        .description(design.summary)
        .supportedFamilies(WidgetSize.families(for: design.sizes))
        .contentMarginsDisabled()
    }
}

struct EditorialClockWidget: Widget {
    let design = DesignCatalog.editorialClock

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: design.id, provider: ClockProvider()) { entry in
            DesignWidgetView(design: design, clock: entry)
        }
        .configurationDisplayName(design.name)
        .description(design.summary)
        .supportedFamilies(WidgetSize.families(for: design.sizes))
        .contentMarginsDisabled()
    }
}

struct EditorialSunMoonWidget: Widget {
    let design = DesignCatalog.editorialSunMoon

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: design.id, provider: WeatherProvider()) { entry in
            DesignWidgetView(design: design, weather: entry)
        }
        .configurationDisplayName(design.name)
        .description(design.summary)
        .supportedFamilies(WidgetSize.families(for: design.sizes))
        .contentMarginsDisabled()
    }
}

struct EditorialCalendarWidget: Widget {
    let design = DesignCatalog.editorialCalendar

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: design.id, provider: CalendarProvider()) { entry in
            DesignWidgetView(design: design, calendar: entry)
        }
        .configurationDisplayName(design.name)
        .description(design.summary)
        .supportedFamilies(WidgetSize.families(for: design.sizes))
        .contentMarginsDisabled()
    }
}

#Preview("Weather", as: .systemLarge) {
    EditorialWeatherWidget()
} timeline: {
    WeatherEntry.sample
    WeatherEntry(date: .now, state: .noLocation)
}

#Preview("Clock", as: .systemMedium) {
    EditorialClockWidget()
} timeline: {
    ClockEntry.sample
}
