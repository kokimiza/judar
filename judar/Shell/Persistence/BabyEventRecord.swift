import Foundation
import SwiftData

@Model
final class BabyEventRecord {
    var id: UUID = UUID()
    var eventTypeRaw: String = ""
    var timestamp: Date = Date()
    // CloudKit sync fields
    var familyId: String = ""  // populated from ProfileViewModel.familyId at event creation
    var cloudKitRecordName: String = ""  // CKRecord.ID.recordName; empty until pushed
    var isSynced: Bool = false  // true once confirmed pushed to CloudKit
    var syncErrorRaw: String = ""  // non-empty when last push failed; cleared on success
    var amount: Int = 0  // ml for formula; 0 = not set / not applicable

    init(eventType: EventType, amount: Int = 0, timestamp: Date = .now) {
        self.id = UUID()
        self.eventTypeRaw = eventType.rawValue
        self.amount = amount
        self.timestamp = timestamp
    }

    init() {}  // required for EventSyncService pull path

    var eventType: EventType? {
        EventType(rawValue: eventTypeRaw)
    }

    func toEventRecord() -> EventRecord? {
        guard let et = eventType else { return nil }
        return EventRecord(eventType: et, timestamp: timestamp)
    }
}
