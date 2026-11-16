import BorneCore
import SwiftUI
import Testing
@testable import BorneDesigns

/// Every design's content must fit inside its widget size, otherwise the
/// canvas grows past the frame and the gold keyline gets clipped.
@MainActor
@Test(arguments: DesignCatalog.cards())
func contentFitsWidgetSize(card: DesignCard) {
    let size = card.size.previewSize
    let content = DesignRegistry.view(for: card, weather: .sample, clock: .sample)
    let fitted = ImageRenderer(content: content.frame(width: size.width, height: size.height)).cgImage
    let natural = ImageRenderer(content: content.fixedSize(horizontal: false, vertical: true).frame(width: size.width))
    natural.proposedSize = ProposedViewSize(width: size.width, height: nil)
    let image = natural.cgImage
    #expect(fitted != nil)
    let height = CGFloat(image?.height ?? 0) / natural.scale
    let width = CGFloat(image?.width ?? 0) / natural.scale
    #expect(height <= size.height + 0.5, "\(card.id) needs \(height)pt tall, has \(size.height)")
    #expect(width <= size.width + 0.5, "\(card.id) needs \(width)pt wide, has \(size.width)")
}

/// Real widget sizes measured on the iPhone 18 Pro simulator (iOS 27),
/// which are a little smaller than our preview sizes.
@MainActor
@Test(arguments: [
    (WidgetSize.large, CGSize(width: 349.67, height: 365)),
    (WidgetSize.extraLarge, CGSize(width: 349.67, height: 565.67)),
])
func weatherFitsOnIPhone18Pro(size: WidgetSize, device: CGSize) {
    let card = DesignCard(design: DesignCatalog.editorialWeather, size: size)
    let content = DesignRegistry.view(for: card, weather: .sample, clock: .sample)
    let r = ImageRenderer(content: content.fixedSize(horizontal: false, vertical: true).frame(width: device.width))
    let height = CGFloat(r.cgImage?.height ?? 0) / r.scale
    #expect(height <= device.height + 0.5, "\(card.id) needs \(height)pt, device has \(device.height)")
}
