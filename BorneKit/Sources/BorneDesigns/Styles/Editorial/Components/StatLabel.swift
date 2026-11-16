import SwiftUI
import WidgetKit

/// Small-caps caption above a serif value, e.g. "RAIN / 44%".
struct StatLabel: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let title: String
    let value: String
    var valueColor: Color? = nil
    var valueSize: CGFloat = 15
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        VStack(alignment: alignment, spacing: 1) {
            EditorialCaption(title)
            Text(value)
                .font(EditorialTheme.numeral(valueSize, weight: .semibold))
                .foregroundStyle(valueColor ?? palette.primary)
                .monospacedDigit()
        }
    }
}

/// Monospaced small-caps label in the secondary color.
struct EditorialCaption: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let text: String
    var size: CGFloat = 9
    var color: Color? = nil

    init(_ text: String, size: CGFloat = 9, color: Color? = nil) {
        self.text = text
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(text.lowercased())
            .font(EditorialTheme.label(size))
            .tracking(EditorialTheme.labelTracking)
            .foregroundStyle(color ?? EditorialPalette(mode, scheme).secondary)
            .lineLimit(1)
    }
}

/// A full-width hairline rule.
struct Hairline: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Rectangle().fill(EditorialPalette(mode, scheme).hairline).frame(height: 0.5)
    }
}
