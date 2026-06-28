import SwiftUI

struct AnalogClockView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            AnalogFace(date: timeline.date)
        }
    }
}

private struct AnalogFace: View {
    let date: Date

    private var angles: (hour: Double, minute: Double, second: Double) {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let h  = Double(comps.hour      ?? 0)
        let m  = Double(comps.minute    ?? 0)
        let s  = Double(comps.second    ?? 0)
        let ns = Double(comps.nanosecond ?? 0)
        let smoothS = s + ns / 1_000_000_000
        return (
            hour:   (h.truncatingRemainder(dividingBy: 12) / 12.0 + m / 720.0) * 360.0,
            minute: (m / 60.0 + smoothS / 3600.0) * 360.0,
            second: smoothS / 60.0 * 360.0
        )
    }

    var body: some View {
        let (hourAngle, minuteAngle, secondAngle) = angles

        Canvas { ctx, size in
            let r      = min(size.width, size.height) / 2.0
            let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)

            drawMarkers(ctx: ctx, center: center, radius: r)
            drawHand(ctx: ctx, center: center, radius: r,
                     angleDeg: hourAngle, length: 0.46, width: 7.5,
                     color: .white, glowRadius: 7)
            drawHand(ctx: ctx, center: center, radius: r,
                     angleDeg: minuteAngle, length: 0.64, width: 4.5,
                     color: .white.opacity(0.9), glowRadius: 5)
            drawSecondHand(ctx: ctx, center: center, radius: r, angleDeg: secondAngle)
            drawCenterJewel(ctx: ctx, center: center)
        }
    }

    // MARK: - Drawing helpers

    private func drawMarkers(ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Minute ticks
        for i in 0..<60 where i % 5 != 0 {
            let rad     = angle(forStep: i, of: 60)
            let outerR  = radius - 5
            let innerR  = radius - 13
            var path    = Path()
            path.move(to: point(center: center, radius: outerR, radians: rad))
            path.addLine(to: point(center: center, radius: innerR, radians: rad))
            ctx.stroke(path, with: .color(.white.opacity(0.35)),
                       style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }

        // Hour markers
        for i in 0..<12 {
            let rad        = angle(forStep: i, of: 12)
            let markerR    = radius - 20
            let isQuarter  = i % 3 == 0
            let dotSize: CGFloat = isQuarter ? 9 : 5.5
            let alpha: CGFloat   = isQuarter ? 0.95 : 0.72
            let pos = point(center: center, radius: markerR, radians: rad)
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: pos.x - dotSize / 2, y: pos.y - dotSize / 2,
                    width: dotSize, height: dotSize
                )),
                with: .color(.white.opacity(alpha))
            )
        }
    }

    private func drawHand(ctx: GraphicsContext, center: CGPoint, radius: CGFloat,
                          angleDeg: Double, length: CGFloat, width: CGFloat,
                          color: Color, glowRadius: CGFloat) {
        let rad = (angleDeg - 90.0) * .pi / 180.0
        let tip = point(center: center, radius: radius * length, radians: rad)

        var path = Path()
        path.move(to: center)
        path.addLine(to: tip)

        ctx.drawLayer { gc in
            gc.addFilter(.blur(radius: glowRadius))
            gc.stroke(path, with: .color(color.opacity(0.6)),
                      style: StrokeStyle(lineWidth: width * 1.6, lineCap: .round))
        }
        ctx.stroke(path, with: .color(color),
                   style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func drawSecondHand(ctx: GraphicsContext, center: CGPoint,
                                radius: CGFloat, angleDeg: Double) {
        let rad          = (angleDeg - 90.0) * .pi / 180.0
        let counterRad   = rad + .pi
        let tip          = point(center: center, radius: radius * 0.70, radians: rad)
        let counterTip   = point(center: center, radius: radius * 0.18, radians: counterRad)

        var path = Path()
        path.move(to: counterTip)
        path.addLine(to: tip)

        let accent = Color(red: 1.0, green: 0.28, blue: 0.12)
        ctx.drawLayer { gc in
            gc.addFilter(.blur(radius: 9))
            gc.stroke(path, with: .color(accent.opacity(0.75)),
                      style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
        ctx.stroke(path, with: .color(accent),
                   style: StrokeStyle(lineWidth: 2, lineCap: .round))

        // Accent dot at pivot
        let dotR: CGFloat = 4
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: center.x - dotR, y: center.y - dotR,
                width: dotR * 2, height: dotR * 2
            )),
            with: .color(accent)
        )
    }

    private func drawCenterJewel(ctx: GraphicsContext, center: CGPoint) {
        let jewel: CGFloat = 10
        ctx.drawLayer { gc in
            gc.addFilter(.blur(radius: 5))
            gc.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - jewel, y: center.y - jewel,
                    width: jewel * 2, height: jewel * 2
                )),
                with: .color(.white.opacity(0.7))
            )
        }
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: center.x - jewel / 2, y: center.y - jewel / 2,
                width: jewel, height: jewel
            )),
            with: .color(.white)
        )
    }

    // MARK: - Geometry utilities

    private func angle(forStep step: Int, of total: Int) -> CGFloat {
        (Double(step) / Double(total) * 2 * .pi) - (.pi / 2)
    }

    private func point(center: CGPoint, radius: CGFloat, radians: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + cos(radians) * radius,
            y: center.y + sin(radians) * radius
        )
    }
}
