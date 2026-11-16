import BorneCore
import SwiftUI
import WidgetKit

struct EditorialClockSmall: View {
    let entry: ClockEntry

    var body: some View {
        AnalogFace(date: entry.date)
            .widgetAccentable()
    }
}
