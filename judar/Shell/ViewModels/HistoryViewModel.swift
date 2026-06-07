import Foundation
import SwiftData

@Observable
@MainActor
final class HistoryViewModel {
    private(set) var groupedDays: [(day: Date, counts: DailyCounts, records: [BabyEventRecord])] = []

    func load(records: [BabyEventRecord], calendar: Calendar = .current) {
        var dayMap: [Date: [BabyEventRecord]] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.timestamp)
            dayMap[day, default: []].append(record)
        }
        groupedDays = dayMap
            .sorted { $0.key > $1.key }
            .map { day, dayRecords in
                let sorted = dayRecords.sorted { $0.timestamp > $1.timestamp }
                var counts = DailyCounts()
                for r in sorted {
                    if let et = r.eventType { counts[et] += 1 }
                }
                return (day, counts, sorted)
            }
    }

    func dayLabel(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "M月d日(E)"
        fmt.locale = Locale(identifier: "ja_JP")
        return fmt.string(from: date)
    }
}
