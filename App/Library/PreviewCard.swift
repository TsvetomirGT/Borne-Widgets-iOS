import BorneCore
import BorneDesigns
import SwiftUI

/// A design rendered at true widget size with live (or sample) data.
/// Content, not chrome — so no glass here.
struct WidgetPreview: View {
    @Environment(AppModel.self) private var model
    let card: DesignCard

    var body: some View {
        let size = card.size.previewSize
        TimelineView(.everyMinute) { context in
            DesignRegistry.view(for: card, weather: model.weatherEntry(at: context.date),
                                clock: model.clockEntry(at: context.date),
                                calendar: model.calendarEntry(at: context.date))
        }
        .frame(width: size.width, height: size.height)
        .containerShape(.rect(cornerRadius: 24, style: .continuous))
        .clipShape(.rect(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.design.name), \(card.size.title)")
    }
}

struct PreviewCard: View {
    let card: DesignCard

    var body: some View {
        NavigationLink(value: card.design) {
            VStack(alignment: .leading, spacing: 8) {
                WidgetPreview(card: card)
                VStack(alignment: .leading, spacing: 1) {
                    Text(card.design.name).font(.footnote.weight(.semibold))
                    Text(card.size.title).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.leading, 4)
            }
        }
        .buttonStyle(.plain)
    }
}
