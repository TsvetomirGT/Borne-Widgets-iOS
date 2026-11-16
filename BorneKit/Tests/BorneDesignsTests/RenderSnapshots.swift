import BorneCore
import Foundation
import SwiftUI
import Testing
@testable import BorneDesigns

/// Renders every design card to PNG for eyeballing.
/// Run with: RENDER_DIR=/some/dir swift test --filter renderAllCards
@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["RENDER_DIR"] != nil))
func renderAllCards() throws {
    let dir = URL(fileURLWithPath: ProcessInfo.processInfo.environment["RENDER_DIR"]!)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let states: [(String, WeatherEntry, CalendarEntry)] = [
        ("", .sample, .sample),
        ("-nolocation", WeatherEntry(date: .now, state: .noLocation), .sample),
        ("-noaccess", .sample, .noAccess(at: .now)),
    ]
    func applies(_ suffix: String, to category: WidgetCategory) -> Bool {
        switch suffix {
        case "-nolocation": category == .weather || category == .sunMoon
        case "-noaccess": category == .calendar
        default: true
        }
    }
    for card in DesignCatalog.cards() {
      for scheme in [ColorScheme.dark, .light] {
        for (stateSuffix, weather, calendar) in states where applies(stateSuffix, to: card.design.category) {
            let suffix = stateSuffix + (scheme == .light ? "-light" : "")
            let size = card.size.previewSize
            let view = DesignRegistry.view(for: card, weather: weather, clock: .sample, calendar: calendar)
                .frame(width: size.width, height: size.height)
                .containerShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .environment(\.colorScheme, scheme)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let image = renderer.cgImage else { Issue.record("no image for \(card.id)"); continue }
            let rep = NSBitmapImageRep(cgImage: image)
            try rep.representation(using: .png, properties: [:])!
                .write(to: dir.appending(path: "\(card.id)\(suffix).png"))
        }
      }
    }
}
