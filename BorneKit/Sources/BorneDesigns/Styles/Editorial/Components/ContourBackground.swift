import SwiftUI
import WidgetKit

/// Slate background with faint topographic contour lines.
struct ContourBackground: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        ZStack {
            LinearGradient(colors: [palette.background, palette.backgroundDeep], startPoint: .top, endPoint: .bottom)
            if palette.showsTexture {
                Canvas { context, size in
                    for path in Self.contours(in: size) {
                        context.stroke(path, with: .color(palette.contour), lineWidth: 0.8)
                    }
                }
            }
        }
    }

    /// Deterministic wobbly rings around two "peaks", like a survey map.
    nonisolated static func contours(in size: CGSize) -> [Path] {
        let peaks: [(CGPoint, CGFloat)] = [
            (CGPoint(x: size.width * 0.78, y: size.height * 0.28), 1.0),
            (CGPoint(x: size.width * 0.18, y: size.height * 0.82), 1.7),
        ]
        let maxRadius = max(size.width, size.height)
        var paths: [Path] = []
        for (center, seed) in peaks {
            var radius: CGFloat = 18
            var ring = 0.0
            while radius < maxRadius * 0.9 {
                var path = Path()
                let steps = 72
                for i in 0...steps {
                    let a = Double(i) / Double(steps) * 2 * .pi
                    let wobble = 1
                        + 0.10 * sin(3 * a + seed + ring * 0.6)
                        + 0.05 * sin(5 * a - seed * 2 + ring * 0.3)
                    let r = radius * wobble
                    let p = CGPoint(x: center.x + r * cos(a), y: center.y + r * 0.82 * sin(a))
                    i == 0 ? path.move(to: p) : path.addLine(to: p)
                }
                path.closeSubpath()
                paths.append(path)
                radius += 16 + CGFloat(ring) * 1.5
                ring += 1
            }
        }
        return paths
    }
}

#Preview {
    ContourBackground().frame(width: 364, height: 382)
}
