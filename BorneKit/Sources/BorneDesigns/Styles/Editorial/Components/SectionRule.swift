import SwiftUI
import WidgetKit

/// Small-caps section title over a hairline, with optional trailing content.
struct SectionRule<Trailing: View>: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let title: String
    var note: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                EditorialCaption(title, size: 8)
                if let note {
                    EditorialCaption("· " + note, size: 8, color: EditorialPalette(mode, scheme).rain)
                }
                Spacer()
                trailing
            }
            Hairline()
        }
        .padding(.top, 2)
    }
}

extension SectionRule where Trailing == EmptyView {
    init(title: String, note: String? = nil) {
        self.init(title: title, note: note) { EmptyView() }
    }
}
