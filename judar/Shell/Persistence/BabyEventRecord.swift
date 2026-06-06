import Foundation
import SwiftData

// CloudKit requires all stored properties to have default values.
@Model
final class BabyEventRecord {
    var id: UUID         = UUID()
    var eventTypeRaw: String = ""
    var timestamp: Date  = Date()

    init(eventType: EventType, timestamp: Date = .now) {
        self.id           = UUID()
        self.eventTypeRaw = eventType.rawValue
        self.timestamp    = timestamp
    }

    var eventType: EventType? {
        EventType(rawValue: eventTypeRaw)
    }

    func toEventRecord() -> EventRecord? {
        guard let et = eventType else { return nil }
        return EventRecord(eventType: et, timestamp: timestamp)
    }
}
