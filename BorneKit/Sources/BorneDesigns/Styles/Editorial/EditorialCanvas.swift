import SwiftUI
import WidgetKit

/// Lays an Editorial widget's content over its background and gold keyline.
/// Widgets supply the background through `containerBackground` instead
/// (so the system can remove it in tinted/clear modes), hence the flag.
struct EditorialCanvas<Content: View>: View {
    var drawsBackground: Bool
    var padding: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        // The frame takes exactly the space offered, and the keyline is an
        // overlay on it, so oversized content can never push the border out.
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { if drawsBackground { ContourBackground() } }
            .overlay { FrameBorder() }
    }
}
