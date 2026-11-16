import BorneCore
import SwiftUI
import UIKit

/// "Allow Calendar access", or a way to Settings once access was refused.
struct CalendarAccessButton: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        switch model.calendarAccess {
        case .granted:
            Label("Calendar access allowed", systemImage: "checkmark.circle")
                .foregroundStyle(.secondary)
        case .notDetermined:
            Button {
                Task { await model.requestCalendarAccess() }
            } label: {
                Label("Allow Calendar access", systemImage: "calendar")
            }
        case .denied:
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                Label("Turn on Calendar access in Settings", systemImage: "gear")
            }
        }
    }
}
