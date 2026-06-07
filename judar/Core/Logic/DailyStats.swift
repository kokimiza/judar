import Foundation

enum DailyStats {

    static func counts(
        from records: [EventRecord],
        for date: Date,
        calendar: Calendar = .current
    ) -> DailyCounts {
        var counts = DailyCounts()
        for record in records
        where calendar.isDate(record.timestamp, inSameDayAs: date) {
            counts[record.eventType] += 1
        }
        return counts
    }

    static func groupByDay(
        records: [EventRecord],
        calendar: Calendar = .current
    ) -> [(day: Date, records: [EventRecord])] {
        var dayMap: [Date: [EventRecord]] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.timestamp)
            dayMap[day, default: []].append(record)
        }
        return
            dayMap
            .sorted { $0.key > $1.key }  // newest day first
            .map { key, value in
                (
                    day: key,
                    records: value.sorted { $0.timestamp > $1.timestamp }
                )
            }
    }
}
