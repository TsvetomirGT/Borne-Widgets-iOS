import BorneCore
import SwiftUI
import WidgetKit

/// Smooth temperature line for the coming hours. Stretches where rain is
/// likely are hatched beneath the line. "Now" is marked at the real time,
/// and each coming hour carries its temperature (every other hour when tight).
struct TemperatureCurve: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var scheme
    let hours: [WeatherSnapshot.Hour]
    let unit: TemperatureUnit
    let timeZone: TimeZone
    var uses24Hour = true
    var showsTimeLabels = true
    /// When set, an orange "Now" dot is placed at this time on the curve.
    var now: Date? = nil
    /// Temperature shown beside the Now dot (e.g. current conditions).
    var nowTemperature: Double? = nil

    nonisolated static let rainThreshold = 50

    var body: some View {
        let palette = EditorialPalette(mode, scheme)
        Canvas { context, size in
            guard hours.count >= 2 else { return }
            let labelBand: CGFloat = showsTimeLabels ? 14 : 0
            let plot = CGRect(x: 4, y: 16, width: size.width - 8, height: size.height - 16 - labelBand - 4)
            let points = Self.points(for: hours.map(\.temperature), in: plot)
            let line = Self.smoothPath(points)

            // Hatched rain regions under the curve.
            for run in Self.rainRuns(hours) {
                let x0 = points[run.lowerBound].x
                let x1 = points[min(run.upperBound + 1, points.count - 1)].x
                var area = line
                area.addLine(to: CGPoint(x: points.last!.x, y: plot.maxY))
                area.addLine(to: CGPoint(x: points.first!.x, y: plot.maxY))
                area.closeSubpath()
                var clipped = context
                clipped.clip(to: area)
                clipped.clip(to: Path(CGRect(x: x0, y: plot.minY - 16, width: x1 - x0, height: plot.height + 16)))
                clipped.stroke(Self.hatch(in: CGRect(x: x0, y: plot.minY - 16, width: x1 - x0, height: plot.height + 20)),
                               with: .color(palette.rain.opacity(0.7)), lineWidth: 0.8)
            }

            // Baseline and line.
            context.stroke(Path { p in
                p.move(to: CGPoint(x: plot.minX, y: plot.maxY))
                p.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
            }, with: .color(palette.hairline), lineWidth: 0.5)
            context.stroke(line, with: .color(palette.primary), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

            // A small point and its temperature at each coming hour.
            let nowPosition = now.flatMap { Self.nowPosition(in: hours, now: $0) }
            for index in Self.valueLabelIndices(hourCount: hours.count, width: plot.width, nowPosition: nowPosition) {
                let p = points[index]
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)),
                             with: .color(palette.primary))
                let label = Text(unit.format(hours[index].temperature))
                    .font(EditorialTheme.numeral(10, weight: .semibold))
                    .foregroundStyle(palette.primary)
                let anchor: UnitPoint = p.x > plot.maxX - 10 ? .bottomTrailing : .bottom
                context.draw(label, at: CGPoint(x: anchor == .bottomTrailing ? p.x + 4 : p.x, y: p.y - 5), anchor: anchor)
            }

            // Now: orange dot at the real time, with the current temperature.
            var nowX: CGFloat?
            if let now, let position = Self.nowPosition(in: hours, now: now) {
                let i = min(Int(position), points.count - 2)
                let f = CGFloat(position - Double(i))
                let p = CGPoint(x: points[i].x + (points[i + 1].x - points[i].x) * f,
                                y: points[i].y + (points[i + 1].y - points[i].y) * f)
                nowX = p.x
                context.fill(Path(ellipseIn: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9)),
                             with: .color(palette.golden))
                let temp = nowTemperature ?? (hours[i].temperature + (hours[i + 1].temperature - hours[i].temperature) * Double(f))
                let nowLabel = Text(unit.format(temp))
                    .font(EditorialTheme.numeral(11, weight: .semibold))
                    .foregroundStyle(palette.golden)
                // A steeply rising line would run through a label above the dot,
                // so then set it below and to the right instead.
                let rising = points[i + 1].y < points[i].y - 6
                if rising {
                    context.draw(nowLabel, at: CGPoint(x: p.x + 7, y: p.y + 1), anchor: .topLeading)
                } else {
                    context.draw(nowLabel, at: CGPoint(x: max(p.x, plot.minX + 8), y: p.y - 7), anchor: .bottom)
                }
                if showsTimeLabels {
                    context.draw(Text("NOW").font(EditorialTheme.label(8)).foregroundStyle(palette.golden),
                                 at: CGPoint(x: max(p.x, plot.minX + 10), y: plot.maxY + 4), anchor: .top)
                }
            }

            // Hour axis: a tick every hour, and a label every hour where it
            // fits (every other hour on narrow widgets), clear of NOW.
            if showsTimeLabels {
                var ticks = Path()
                for p in points {
                    ticks.move(to: CGPoint(x: p.x, y: plot.maxY))
                    ticks.addLine(to: CGPoint(x: p.x, y: plot.maxY + 2.5))
                }
                context.stroke(ticks, with: .color(palette.secondary.opacity(0.6)), lineWidth: 0.6)

                let stride = Self.labelStride(hourCount: hours.count, width: plot.width)
                let fullLabels = Self.usesFullTimeLabels(hourCount: hours.count, width: plot.width)
                for index in Swift.stride(from: stride, to: hours.count, by: stride) {
                    if let nowX, abs(points[index].x - nowX) < (fullLabels ? 34 : 16) { continue }
                    let time = hours[index].time
                    let label = fullLabels
                        ? EditorialFormat.hour(time, timeZone, uses24Hour: uses24Hour)
                        : EditorialFormat.compactHour(time, timeZone, uses24Hour: uses24Hour)
                    let text = Text(label)
                        .font(EditorialTheme.label(7))
                        .foregroundStyle(palette.secondary)
                    context.draw(text, at: CGPoint(x: points[index].x, y: plot.maxY + 4), anchor: .top)
                }
            }
        }
    }

    /// Hours that get a temperature label: those after now, every hour when
    /// labels have room (every other hour when tight), none crowding the Now dot.
    nonisolated static func valueLabelIndices(hourCount: Int, width: CGFloat, nowPosition: Double?,
                                              labelWidth: CGFloat = 24) -> [Int] {
        guard hourCount > 1 else { return [] }
        let spacing = width / CGFloat(hourCount - 1)
        let stride = (1...4).first { spacing * CGFloat($0) >= labelWidth } ?? 4
        return Swift.stride(from: 0, to: hourCount, by: stride).filter { index in
            guard let nowPosition else { return true }
            return Double(index) > nowPosition && CGFloat(Double(index) - nowPosition) * spacing >= labelWidth
        }
    }

    /// Full "14:00" labels when hours are far enough apart, else "14".
    nonisolated static func usesFullTimeLabels(hourCount: Int, width: CGFloat) -> Bool {
        guard hourCount > 1 else { return true }
        return width / CGFloat(hourCount - 1) >= 30
    }

    /// Hours between axis labels: 1 when every hour has room, else 2 or 3.
    nonisolated static func labelStride(hourCount: Int, width: CGFloat, minSpacing: CGFloat = 13.5) -> Int {
        guard hourCount > 1 else { return 1 }
        let spacing = width / CGFloat(hourCount - 1)
        return (1...3).first { spacing * CGFloat($0) >= minSpacing } ?? 4
    }

    /// Fractional hour index of `now` (0 = start of the first hour), or nil
    /// when `now` falls outside the plotted hours.
    nonisolated static func nowPosition(in hours: [WeatherSnapshot.Hour], now: Date) -> Double? {
        guard let first = hours.first, hours.count >= 2 else { return nil }
        let position = now.timeIntervalSince(first.time) / 3600
        guard position >= 0, position <= Double(hours.count - 1) else { return nil }
        return position
    }


    nonisolated static func points(for temps: [Double], in rect: CGRect) -> [CGPoint] {
        let lo = temps.min()!, hi = temps.max()!
        let span = max(hi - lo, 4)   // avoid exaggerating tiny changes
        let mid = (hi + lo) / 2
        return temps.enumerated().map { i, t in
            CGPoint(
                x: rect.minX + rect.width * CGFloat(i) / CGFloat(temps.count - 1),
                y: rect.midY - rect.height * CGFloat((t - mid) / span) * 0.9
            )
        }
    }

    /// Catmull-Rom spline through the points, as cubic Béziers.
    nonisolated static func smoothPath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first)
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(i + 2, pts.count - 1)]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }

    /// Index ranges of consecutive hours where rain is likely.
    nonisolated static func rainRuns(_ hours: [WeatherSnapshot.Hour]) -> [ClosedRange<Int>] {
        var runs: [ClosedRange<Int>] = []
        var start: Int?
        for (i, h) in hours.enumerated() {
            if h.precipitationProbability >= rainThreshold {
                if start == nil { start = i }
            } else if let s = start {
                runs.append(s...(i - 1)); start = nil
            }
        }
        if let s = start { runs.append(s...(hours.count - 1)) }
        return runs
    }

    nonisolated static func hatch(in rect: CGRect) -> Path {
        var p = Path()
        var x = rect.minX - rect.height
        while x < rect.maxX {
            p.move(to: CGPoint(x: x, y: rect.maxY))
            p.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += 4
        }
        return p
    }
}

#Preview {
    let s = WeatherSnapshot.sample
    TemperatureCurve(hours: s.hours(from: .now, count: 18), unit: .celsius, timeZone: s.timeZone)
        .frame(width: 330, height: 90)
        .padding()
        .background(EditorialTheme.background)
}
