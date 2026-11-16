import BorneCore
import SwiftUI
import WidgetKit

/// A dashed arc from sunrise to sunset; the travelled part is solid and an
/// orange dot marks the sun's position now.
struct SunArc: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let sunrise: Date
    let sunset: Date
    let now: Date
    let timeZone: TimeZone
    var uses24Hour = true
    var showsNowLabel = true

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        let progress = SunTimes.progress(now: now, sunrise: sunrise, sunset: sunset)
        VStack(spacing: 2) {
            Canvas { context, size in
                let rect = CGRect(x: 6, y: showsNowLabel ? 14 : 6, width: size.width - 12,
                                  height: (size.height - (showsNowLabel ? 14 : 6)) * 2)
                let arc = Self.arc(in: rect, from: 0, to: 1)
                context.stroke(arc, with: .color(palette.secondary),
                               style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: rect.minX - 4, y: rect.midY))
                    p.addLine(to: CGPoint(x: rect.maxX + 4, y: rect.midY))
                }, with: .color(palette.hairline), lineWidth: 0.5)
                if let progress {
                    context.stroke(Self.arc(in: rect, from: 0, to: progress), with: .color(palette.primary), lineWidth: 1.4)
                    let p = Self.point(in: rect, at: progress)
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10)),
                                 with: .color(palette.golden))
                    if showsNowLabel {
                        context.draw(Text("Now").font(EditorialTheme.italic(10)).foregroundStyle(palette.primary),
                                     at: CGPoint(x: p.x, y: p.y - 8), anchor: .bottom)
                    }
                }
            }
            HStack {
                EditorialCaption(EditorialFormat.time(sunrise, timeZone, uses24Hour: uses24Hour), size: 8, color: palette.primary)
                Spacer()
                EditorialCaption(EditorialFormat.time(sunset, timeZone, uses24Hour: uses24Hour), size: 8, color: palette.primary)
            }
        }
    }

    /// Upper half of the ellipse inscribed in `rect`, from left (0) to right (1).
    nonisolated static func arc(in rect: CGRect, from: Double, to: Double) -> Path {
        var path = Path()
        let steps = 48
        for i in 0...steps {
            let t = from + (to - from) * Double(i) / Double(steps)
            let p = point(in: rect, at: t)
            i == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        return path
    }

    nonisolated static func point(in rect: CGRect, at t: Double) -> CGPoint {
        let angle = Double.pi * (1 - t)
        return CGPoint(x: rect.midX + rect.width / 2 * cos(angle), y: rect.midY - rect.height / 2 * sin(angle))
    }
}

#Preview {
    let s = WeatherSnapshot.sample
    let day = s.today(at: .now)!
    SunArc(sunrise: day.sunrise, sunset: day.sunset, now: day.sunrise.addingTimeInterval(3 * 3600), timeZone: s.timeZone)
        .frame(width: 150, height: 70)
        .padding()
        .background(EditorialTheme.background)
}
