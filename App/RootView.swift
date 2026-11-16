import SwiftUI

struct RootView: View {
    enum TabID: Hashable { case library, settings, search }
    @State private var tab: TabID = .library

    var body: some View {
        TabView(selection: $tab) {
            Tab("Library", systemImage: "square.grid.2x2", value: TabID.library) {
                LibraryView()
            }
            Tab("Settings", systemImage: "gearshape", value: TabID.settings) {
                SettingsView()
            }
            Tab(value: TabID.search, role: .search) {
                LibraryView(isSearch: true)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
