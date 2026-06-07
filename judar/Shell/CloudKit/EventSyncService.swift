import CloudKit
import Foundation
import OSLog
import SwiftData

private let synclog = Logger(subsystem: "productions.jocarium.judar", category: "EventSyncService")

// Imperative Shell: bridges CloudKit records ↔ SwiftData local cache.
@Observable
@MainActor
final class EventSyncService {
    private let cloudKit: CloudKitSyncService
    private(set) var isSyncing = false
    var lastSyncError: Error?

    init(cloudKit: CloudKitSyncService) {
        self.cloudKit = cloudKit
    }

    // Push local unsent events to CloudKit (called after logEvent or on app foreground)
    func pushPending(
        records: [BabyEventRecord],
        familyId: String,
        userId: String
    ) async {
        guard cloudKit.isAvailable, !familyId.isEmpty else {
            synclog.warning("⚠️ pushPending skip — available=\(self.cloudKit.isAvailable) familyId=\(familyId.isEmpty ? "<empty>" : "set", privacy: .public)")
            return
        }
        let pending = records.filter { !$0.isSynced }
        synclog.debug("▶ pushPending count=\(pending.count)")
        for record in pending {
            synclog.debug("  → push type=\(record.eventTypeRaw, privacy: .public) ts=\(record.timestamp)")
            do {
                let ck = try await cloudKit.pushEvent(
                    eventTypeRaw: record.eventTypeRaw,
                    timestamp: record.timestamp,
                    familyId: familyId,
                    userId: userId
                )
                record.cloudKitRecordName = ck.recordID.recordName
                record.isSynced = true
                record.syncErrorRaw = ""
                record.familyId = familyId
                synclog.debug("  ✅ pushed recordName=\(ck.recordID.recordName, privacy: .public)")
            } catch {
                record.syncErrorRaw = error.localizedDescription
                lastSyncError = error
                synclog.error("  ❌ push failed type=\(record.eventTypeRaw, privacy: .public) error=\(error, privacy: .public)")
            }
        }
        synclog.debug("◀ pushPending done")
    }

    // Pull events created by other family members and insert as local records
    func pull(familyId: String, since: Date, into context: ModelContext)
        async throws
    {
        guard cloudKit.isAvailable, !familyId.isEmpty else { return }
        isSyncing = true
        defer { isSyncing = false }

        let ckRecords = try await cloudKit.fetchEvents(
            familyId: familyId,
            since: since
        )
        let existing =
            (try? context.fetch(FetchDescriptor<BabyEventRecord>())) ?? []
        let seenNames = Set(existing.compactMap(\.cloudKitRecordName))

        for ck in ckRecords {
            let recordName = ck.recordID.recordName
            guard !seenNames.contains(recordName) else { continue }
            guard
                let typeRaw = ck[EventF.eventTypeRaw] as? String,
                let ts = ck[EventF.timestamp] as? Date
            else { continue }

            let local = BabyEventRecord()
            local.eventTypeRaw = typeRaw
            local.timestamp = ts
            local.familyId = familyId
            local.cloudKitRecordName = recordName
            local.isSynced = true
            context.insert(local)
        }
    }

    // Refresh enemy cache from CloudKit; no-op if CloudKit empty (keeps hardcoded fallback)
    func refreshEnemies(into context: ModelContext) async throws {
        guard cloudKit.isAvailable else { return }
        let ckRecords = try await cloudKit.fetchAllEnemies()
        guard !ckRecords.isEmpty else { return }

        let old =
            (try? context.fetch(FetchDescriptor<CachedEnemyRecord>())) ?? []
        old.forEach { context.delete($0) }

        for ck in ckRecords {
            let cached = CachedEnemyRecord()
            cached.cloudKitRecordName = ck.recordID.recordName
            cached.name = ck[EnemyF.name] as? String ?? ""
            cached.maxHP =
                (ck[EnemyF.maxHP] as? Int) ?? (ck[EnemyF.maxHP] as? NSNumber)?
                .intValue ?? 10
            cached.attackPower =
                (ck[EnemyF.attackPower] as? Int)
                ?? (ck[EnemyF.attackPower] as? NSNumber)?.intValue ?? 5
            cached.asciiArt = ck[EnemyF.asciiArt] as? String ?? ""
            cached.resistancesJSON = encode(
                cloudKit.stringArray(from: ck, key: EnemyF.resistances)
            )
            cached.weaknessesJSON = encode(
                cloudKit.stringArray(from: ck, key: EnemyF.weaknesses)
            )
            context.insert(cached)
        }
    }

    private func encode(_ strings: [String]) -> String {
        (try? String(data: JSONEncoder().encode(strings), encoding: .utf8))
            ?? "[]"
    }
}
