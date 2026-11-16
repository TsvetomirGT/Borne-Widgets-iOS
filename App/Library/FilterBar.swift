import BorneCore
import SwiftUI

/// Filter state for the library.
struct LibraryFilter: Equatable {
    var size: WidgetSize?
    var category: WidgetCategory?
    var style: WidgetStyle?
}

/// Floating rows of Liquid Glass chips. Chips share a GlassEffectContainer
/// so neighbours blend, and selection animates between glass variants.
struct FilterBar: View {
    @Binding var filter: LibraryFilter
    @Namespace private var glass

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                chipRow("Size", options: WidgetSize.allCases, title: \.title, selection: $filter.size)
                chipRow("Category", options: WidgetCategory.allCases, title: \.title, selection: $filter.category)
                if WidgetStyle.allCases.count > 1 {
                    chipRow("Style", options: WidgetStyle.allCases, title: \.title, selection: $filter.style)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private func chipRow<Option: Hashable & Identifiable>(
        _ label: String, options: [Option], title: KeyPath<Option, String>, selection: Binding<Option?>
    ) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip("All", id: "\(label).all", isSelected: selection.wrappedValue == nil) {
                    selection.wrappedValue = nil
                }
                ForEach(options) { option in
                    chip(option[keyPath: title], id: "\(label).\(option.id)", isSelected: selection.wrappedValue == option) {
                        selection.wrappedValue = selection.wrappedValue == option ? nil : option
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }

    private func chip(_ text: String, id: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.bouncy) { action() }
        } label: {
            Text(text)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .glassEffect(isSelected ? .regular.tint(.accentColor).interactive() : .regular.interactive(), in: .capsule)
        .glassEffectID(id, in: glass)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
