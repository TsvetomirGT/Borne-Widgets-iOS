import BorneCore
import SwiftUI
import WidgetKit

/// The moon's disc with its lit portion for the given phase.
struct MoonGlyph: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let phase: MoonPhase

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        Canvas { context, size in
            let r = min(size.width, size.height) / 2 - 1
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let disc = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
            context.fill(disc, with: .color(palette.moonShadow))
            context.fill(Self.litPath(center: c, radius: r, fraction: phase.fraction), with: .color(palette.moonLit))
            context.stroke(disc, with: .color(palette.hairline), lineWidth: 0.5)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(phase.name.rawValue)
    }

    /// Lit limb (a semicircle on the sunward side) closed by the terminator,
    /// a half-ellipse whose width follows the phase.
    nonisolated static func litPath(center c: CGPoint, radius r: CGFloat, fraction f: Double) -> Path {
        let waxing = f < 0.5
        let k = CGFloat(cos(2 * .pi * f)) * r * (waxing ? 1 : -1)
        var path = Path()
        // Limb: top → bottom on the lit side.
        path.addArc(center: c, radius: r, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: !waxing)
        // Terminator: bottom → top through (c.x + k, c.y).
        let steps = 40
        for i in 0...steps {
            let t = Double.pi / 2 - Double.pi * Double(i) / Double(steps)
            path.addLine(to: CGPoint(x: c.x + k * CGFloat(cos(t)), y: c.y + r * CGFloat(sin(t))))
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    HStack {
        ForEach([0.1, 0.25, 0.4, 0.5, 0.62, 0.75, 0.9], id: \.self) { f in
            MoonGlyph(phase: MoonPhase(date: MoonPhase.referenceDate(fraction: f))).frame(width: 36)
        }
    }
    .padding()
    .background(EditorialTheme.background)
}

extension MoonPhase {
    /// A date at the given cycle fraction (for previews).
    static func referenceDate(fraction: Double) -> Date {
        Date(timeIntervalSince1970: 947_182_440 + fraction * synodicMonth * 86_400)
    }
}
