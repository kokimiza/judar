import Foundation
import SwiftData

@Model
final class BabyEventRecord {
    var id: UUID              = UUID()
    var eventTypeRaw: String  = ""
    var timestamp: Date       = Date()
    // CloudKit sync fields
    var familyId: String      = ""   // populated from ProfileViewModel.familyId at event creation
    var cloudKitRecordName: String = ""  // CKRecord.ID.recordName; empty until pushed
    var isSynced: Bool        = false    // true once confirmed pushed to CloudKit

    init(eventType: EventType, timestamp: Date = .now) {
        self.id           = UUID()
        self.eventTypeRaw = eventType.rawValue
        self.timestamp    = timestamp
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
