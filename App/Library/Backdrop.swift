import SwiftUI

/// Deep, quiet backdrop behind the previews so glass and the dark widgets
/// both read well. Plain content, not glass.
struct Backdrop: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.07, green: 0.09, blue: 0.13), Color(red: 0.03, green: 0.04, blue: 0.06)]
                : [Color(red: 0.93, green: 0.94, blue: 0.96), Color(red: 0.84, green: 0.86, blue: 0.90)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
