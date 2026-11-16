import SwiftUI
import WidgetKit

@main
struct BorneWidgetBundle: WidgetBundle {
    var body: some Widget {
        EditorialWeatherWidget()
        EditorialClockWidget()
        EditorialSunMoonWidget()
        EditorialCalendarWidget()
    }
}
