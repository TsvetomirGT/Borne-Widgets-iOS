import BorneCore
import BorneDesigns
import SwiftUI
import WidgetKit

/// Renders a catalog design for whatever family the widget is placed in.
struct DesignWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let design: DesignInfo
    var weather: WeatherEntry = .sample
    var clock: ClockEntry = .sample
    var calendar: CalendarEntry = .sample

    var body: some View {
        let size = WidgetSize(family) ?? design.sizes[0]
        DesignRegistry.view(
            for: DesignCard(design: design, size: size),
            weather: weather, clock: clock, calendar: calendar,
            drawsBackground: false
        )
        .containerBackground(for: .widget) {
            DesignRegistry.background(for: design)
        }
    }
}
