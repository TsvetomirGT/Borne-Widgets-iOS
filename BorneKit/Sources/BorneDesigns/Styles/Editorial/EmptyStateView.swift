import SwiftUI
import WidgetKit

/// Quiet, on-style message for widgets without data.
struct EditorialEmptyState: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let message: String
    var symbol = "location.slash"

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(palette.secondary)
            Text(message)
                .font(EditorialTheme.italic(15))
                .foregroundStyle(palette.primary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
