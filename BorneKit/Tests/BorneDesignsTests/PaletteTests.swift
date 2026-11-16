import SwiftUI
import Testing
import WidgetKit
@testable import BorneDesigns

@Test func lightSchemeUsesPaperAndInk() {
    let p = EditorialPalette(.fullColor, .light)
    #expect(p.background == EditorialTheme.Light.paper)
    #expect(p.primary == EditorialTheme.Light.ink)
    #expect(p.rain == EditorialTheme.Light.rain)
    #expect(p.showsTexture)
}

@Test func darkSchemeUsesSlate() {
    let p = EditorialPalette(.fullColor, .dark)
    #expect(p.background == EditorialTheme.background)
    #expect(p.primary == EditorialTheme.primary)
}

@Test func tintedModesIgnoreScheme() {
    #expect(EditorialPalette(.accented, .light).primary == .white)
    #expect(!EditorialPalette(.accented, .light).showsTexture)
}

@Test func moonLitSideIsBrightOnBothBackgrounds() {
    let light = EditorialPalette(.fullColor, .light)
    #expect(light.moonLit == EditorialTheme.Light.moonLit)
    #expect(light.moonShadow == EditorialTheme.Light.moonShadow)
    let dark = EditorialPalette(.fullColor, .dark)
    #expect(dark.moonLit == EditorialTheme.primary)
}
