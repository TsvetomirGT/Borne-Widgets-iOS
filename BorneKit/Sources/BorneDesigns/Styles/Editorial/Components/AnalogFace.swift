import SwiftUI
import WidgetKit

/// Hairline analog dial with serif numerals at the quarters.
struct AnalogFace: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let date: Date
    var timeZone: TimeZone = .current
    var showsNumerals = true

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let r = side / 2
            ZStack {
                Canvas { context, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    context.stroke(Path(ellipseIn: CGRect(x: c.x - r + 0.5, y: c.y - r + 0.5, width: 2 * r - 1, height: 2 * r - 1)),
                                   with: .color(palette.hairline), lineWidth: 0.6)
                    for tick in 0..<60 {
                        let major = tick % 5 == 0
                        let a = Double(tick) / 60 * 2 * .pi
                        let outer = r - 4, inner = r - (major ? 11 : 7)
                        var p = Path()
                        p.move(to: CGPoint(x: c.x + outer * sin(a), y: c.y - outer * cos(a)))
                        p.addLine(to: CGPoint(x: c.x + inner * sin(a), y: c.y - inner * cos(a)))
                        context.stroke(p, with: .color(major ? palette.primary : palette.secondary.opacity(0.6)),
                                       lineWidth: major ? 1.2 : 0.5)
                    }
                    let (h, m) = Self.handAngles(date, timeZone)
                    drawHand(&context, c, angle: h, length: r * 0.5, width: 2.6, color: palette.primary)
                    drawHand(&context, c, angle: m, length: r * 0.78, width: 1.4, color: palette.primary)
                    context.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)), with: .color(palette.golden))
                }
                if showsNumerals {
                    ForEach([12, 3, 6, 9], id: \.self) { n in
                        let a = Double(n % 12) / 12 * 2 * .pi
                        let d = r - 22
                        Text("\(n)")
                            .font(EditorialTheme.numeral(side * 0.11, weight: .semibold))
                            .foregroundStyle(palette.primary)
                            .position(x: geo.size.width / 2 + d * sin(a), y: geo.size.height / 2 - d * cos(a))
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func drawHand(_ ctx: inout GraphicsContext, _ c: CGPoint, angle: Double, length: CGFloat, width: CGFloat, color: Color) {
        var p = Path()
        p.move(to: CGPoint(x: c.x - 6 * sin(angle), y: c.y + 6 * cos(angle)))
        p.addLine(to: CGPoint(x: c.x + length * sin(angle), y: c.y - length * cos(angle)))
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// Hour and minute hand angles in radians, clockwise from 12.
    nonisolated static func handAngles(_ date: Date, _ zone: TimeZone) -> (hour: Double, minute: Double) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        let comps = cal.dateComponents([.hour, .minute], from: date)
        let minutes = Double((comps.hour ?? 0) % 12 * 60 + (comps.minute ?? 0))
        return (minutes / 720 * 2 * .pi, Double(comps.minute ?? 0) / 60 * 2 * .pi)
    }
}

#Preview {
    AnalogFace(date: .now).frame(width: 150).padding().background(EditorialTheme.background)
}
