import BorneCore
import SwiftUI

struct LibraryView: View {
    @Environment(AppModel.self) private var model
    var isSearch = false

    @State private var filter = LibraryFilter()
    @State private var query = ""

    private var cards: [DesignCard] {
        DesignCatalog.cards(size: filter.size, category: filter.category, style: filter.style, query: query)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .center, spacing: 28) {
                    if model.isUsingSampleWeather {
                        Label("Previews show sample weather until a location is set.", systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    ForEach(rows(cards), id: \.first!.id) { row in
                        HStack(alignment: .top, spacing: 24) {
                            ForEach(row) { PreviewCard(card: $0) }
                        }
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .animation(.smooth, value: cards.map(\.id))
            }
            .background { Backdrop() }
            .overlay {
                if cards.isEmpty {
                    ContentUnavailableView("No widgets match", systemImage: "square.dashed",
                                           description: Text("Try a different size or category."))
                }
            }
            .safeAreaInset(edge: .top) {
                if !isSearch { FilterBar(filter: $filter) }
            }
            .navigationTitle(isSearch ? "Search" : "Borne")
            .navigationDestination(for: DesignInfo.self) { DesignDetailView(design: $0) }
            .modifier(SearchableIf(isSearch: isSearch, query: $query))
        }
    }

    /// Pairs consecutive small widgets side by side; others take a full row.
    private func rows(_ cards: [DesignCard]) -> [[DesignCard]] {
        var rows: [[DesignCard]] = []
        for card in cards {
            if card.size == .small, let last = rows.last, last.count == 1, last[0].size == .small {
                rows[rows.count - 1].append(card)
            } else {
                rows.append([card])
            }
        }
        return rows
    }
}

private struct SearchableIf: ViewModifier {
    let isSearch: Bool
    @Binding var query: String

    func body(content: Content) -> some View {
        if isSearch {
            content.searchable(text: $query, prompt: "Weather, clock, moon…")
        } else {
            content
        }
    }
}
