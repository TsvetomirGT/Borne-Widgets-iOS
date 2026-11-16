import BorneCore
import SwiftUI

struct DesignDetailView: View {
    @Environment(AppModel.self) private var model
    let design: DesignInfo
    @State private var showingHowTo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text(design.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if design.category == .calendar && model.calendarAccess != .granted {
                    CalendarAccessButton()
                        .buttonStyle(.glass)
                }

                ForEach(design.sizes) { size in
                    VStack(spacing: 8) {
                        WidgetPreview(card: DesignCard(design: design, size: size))
                        Text(size.title).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .background { Backdrop() }
        .navigationTitle(design.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaBar(edge: .bottom) {
            Button {
                showingHowTo = true
            } label: {
                Label("How to add", systemImage: "plus.square.on.square")
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingHowTo) {
            HowToAddSheet(design: design)
                .presentationDetents([.medium])
        }
    }
}

private struct HowToAddSheet: View {
    let design: DesignInfo
    @Environment(\.dismiss) private var dismiss

    private var steps: [(String, String)] {
        [
            ("hand.tap", "Touch and hold an empty area of your Home Screen until the apps jiggle."),
            ("plus.circle", "Tap Edit in the top corner, then Add Widget."),
            ("magnifyingglass", "Search for \u{201C}Borne\u{201D}."),
            ("square.grid.2x2", "Pick \u{201C}\(design.name)\u{201D}, swipe to the size you want, and tap Add Widget."),
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    Label {
                        Text(step.1)
                    } icon: {
                        Image(systemName: step.0).foregroundStyle(.tint)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add to Home Screen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }
}
