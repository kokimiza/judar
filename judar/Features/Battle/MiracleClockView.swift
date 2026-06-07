import SwiftUI

// MARK: - MiracleClockView

struct MiracleClockView: View {
    let events: [BabyEventRecord]

    private static let size: CGFloat = 124

    var body: some View {
        TimelineView(.animation) { ctx in
            ZStack {
                clockFace
                markerLayer(at: ctx.date)
                handLayer(at: ctx.date)
                Circle()
                    .fill(Color.rpgGold)
                    .frame(width: 5, height: 5)
            }
            .frame(width: Self.size, height: Self.size)
        }
    }

    // MARK: - Clock face

    private var clockFace: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = size.width / 2 - 1.5

            ctx.stroke(
                Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                with: .color(.rpgBorder.opacity(0.55)),
                lineWidth: 1
            )

            for i in 0..<60 {
                let angle = Double(i) / 60 * .pi * 2 - .pi / 2
                let isHour = i % 5 == 0
                let inner = r * (isHour ? 0.80 : 0.89)
                let start = CGPoint(x: c.x + cos(angle) * inner, y: c.y + sin(angle) * inner)
                let end   = CGPoint(x: c.x + cos(angle) * r,     y: c.y + sin(angle) * r)
                var tick = Path()
                tick.move(to: start)
                tick.addLine(to: end)
                ctx.stroke(
                    tick,
                    with: .color(.rpgBorder.opacity(isHour ? 0.55 : 0.20)),
                    style: StrokeStyle(lineWidth: isHour ? 1.2 : 0.5)
                )
            }
        }
    }

    // MARK: - Event markers

    private func markerLayer(at now: Date) -> some View {
        let r = (Self.size / 2 - 1.5) * 0.70
        return Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for record in todayEvents(before: now) {
                guard let et = record.eventType else { continue }
                let angle = clockAngle(for: record.timestamp)
                let x = c.x + cos(angle) * r
                let y = c.y + sin(angle) * r
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5)),
                    with: .color(et.accentColor)
                )
            }
        }
    }

    // MARK: - Hands

    private func handLayer(at date: Date) -> some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = size.width / 2 - 1.5
            let cal = Calendar.current

            let h = Double(cal.component(.hour,   from: date)).truncatingRemainder(dividingBy: 12)
            let m = Double(cal.component(.minute, from: date))
            let s = Double(cal.component(.second, from: date))

            let hourAngle   = (h + m / 60) / 12 * .pi * 2 - .pi / 2
            let minuteAngle = (m + s / 60) / 60 * .pi * 2 - .pi / 2

            func drawHand(angle: Double, length: Double, width: CGFloat) {
                let tip = CGPoint(x: c.x + cos(angle) * length, y: c.y + sin(angle) * length)
                var p = Path()
                p.move(to: c)
                p.addLine(to: tip)
                ctx.stroke(p, with: .color(.rpgGold), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }

            drawHand(angle: hourAngle,   length: r * 0.50, width: 2.5)
            drawHand(angle: minuteAngle, length: r * 0.72, width: 1.5)
        }
    }

    // MARK: - Helpers

    private func todayEvents(before now: Date) -> [BabyEventRecord] {
        let start = Calendar.current.startOfDay(for: now)
        return events.filter { $0.timestamp >= start && $0.timestamp <= now }
    }

    private func clockAngle(for date: Date) -> Double {
        let cal = Calendar.current
        let h = Double(cal.component(.hour,   from: date)).truncatingRemainder(dividingBy: 12)
        let m = Double(cal.component(.minute, from: date))
        let s = Double(cal.component(.second, from: date))
        return (h + m / 60 + s / 3600) / 12 * .pi * 2 - .pi / 2
    }
}
