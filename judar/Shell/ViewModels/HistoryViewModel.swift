import Foundation
import SwiftData

@Observable
@MainActor
final class HistoryViewModel {
    private(set) var groupedDays: [(day: Date, counts: DailyCounts, records: [EventRecord])] = []

    func load(records: [BabyEventRecord], calendar: Calendar = .current) {
        let eventRecords = records.compactMap { $0.toEventRecord() }
        let grouped = DailyStats.groupByDay(records: eventRecords, calendar: calendar)
        groupedDays = grouped.map { day, dayRecords in
            var counts = DailyCounts()
            for r in dayRecords { counts[r.eventType] += 1 }
            return (day, counts, dayRecords)
        }
    }

    func dayLabel(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "M月d日(E)"
        fmt.locale = Locale(identifier: "ja_JP")
        return fmt.string(from: date)
    }

    func delete(record: BabyEventRecord, from context: ModelContext) {
        context.delete(record)
    }
}
