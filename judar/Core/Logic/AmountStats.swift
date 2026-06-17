import Foundation

struct DailyAmount: Identifiable, Sendable {
    let day: Date
    let eventType: EventType
    let totalMl: Int

    var id: String { "\(day.timeIntervalSince1970)_\(eventType.rawValue)" }
}

enum AmountStats {
    // Always emits one entry per (day, type) — including zeros — so charts
    // render a continuous date axis even on days with no records.
    static func dailyTotals(
        days: [Date],
        records: [(eventType: EventType, timestamp: Date, amount: Int)],
        types: [EventType] = [.formula, .pumpedMilk],
        calendar: Calendar = .current
    ) -> [DailyAmount] {
        var totals: [Date: [EventType: Int]] = [:]
        for r in records where types.contains(r.eventType) {
            let day = calendar.startOfDay(for: r.timestamp)
            totals[day, default: [:]][r.eventType, default: 0] += r.amount
        }
        return days.flatMap { day in
            types.map { type in
                DailyAmount(
                    day: day,
                    eventType: type,
                    totalMl: totals[day]?[type] ?? 0
                )
            }
        }
    }
}
