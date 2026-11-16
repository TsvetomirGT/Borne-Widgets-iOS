import BorneCore
import SwiftUI

/// Searchable list of cities from Open-Meteo geocoding.
struct CitySearchView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let title: String
    let onPick: (SavedLocation) -> Void

    @State private var query = ""
    @State private var results: [SavedLocation] = []
    @State private var failed = false

    var body: some View {
        NavigationStack {
            List(results, id: \.self) { city in
                Button {
                    onPick(city)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(city.name).foregroundStyle(.primary)
                        if let region = city.region, !region.isEmpty {
                            Text(region).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .overlay {
                if failed {
                    ContentUnavailableView("Search unavailable", systemImage: "wifi.slash",
                                           description: Text("Check your connection and try again."))
                } else if results.isEmpty && query.count >= 2 {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "City name")
            .task(id: query) {
                try? await Task.sleep(for: .milliseconds(300))   // debounce
                guard !Task.isCancelled else { return }
                do {
                    results = try await model.searchCities(query)
                    failed = false
                } catch where error.isCancellation || Task.isCancelled {
                    // Superseded by newer typing; not a failure.
                } catch {
                    failed = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}
