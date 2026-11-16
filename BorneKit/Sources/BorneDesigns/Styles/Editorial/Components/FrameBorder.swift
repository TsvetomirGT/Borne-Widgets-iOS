import SwiftUI
import WidgetKit

/// The thin gold keyline inset from the widget edge.
struct FrameBorder: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    var inset: CGFloat = 4

    var body: some View {
        ContainerRelativeShape()
            .inset(by: inset)
            .strokeBorder(EditorialPalette(mode, scheme).gold, lineWidth: 1)
    }
}
