import SwiftUI
import SwiftData
import CloudKit

@Observable
@MainActor
final class BattleViewModel {
    private(set) var battleState: BattleState
    private let modelContext: ModelContext
    private let cloudKit: CloudKitSyncService

    // Populated from CachedEnemyRecord (CloudKit) on init; falls back to EnemyRoster.all
    private var availableEnemyTemplates: [EnemyTemplate] = []

    init(modelContext: ModelContext, cloudKit: CloudKitSyncService) {
        self.modelContext = modelContext
        self.cloudKit     = cloudKit

        let first = EnemyRoster.firstEnemy()
        self.battleState = BattleState(
            enemy: first,
            partyHP: BattleState.initialPartyHP,
            killStreak: 0,
            battleLog: [
                "> *** judar バトル開始 ***",
                "> \(first.template.name) が あらわれた！",
                "> [HP:\(first.template.maxHP)]",
            ]
        )

        Task { await loadCachedEnemies() }
    }

    // MARK: - Public API

    // Called by the 4 input buttons.
    // familyId/userId come from ProfileViewModel (injected by BattleView).
    func logEvent(
        _ eventType: EventType,
        allRecords: [BabyEventRecord],
        familyId: String,
        userId: String
    ) {
        // 1. Persist locally (Shell)
        let record = BabyEventRecord(eventType: eventType)
        record.familyId = familyId
        modelContext.insert(record)

        // 2. Pure battle resolution (Core)
        let (newState, _) = BattleLogic.resolveAttack(
            eventType: eventType,
            state: battleState,
            availableEnemies: availableEnemyTemplates,
            randomSource: .live
        )
        battleState = newState

        // 3. Widget sync (Shell)
        let eventRecords = allRecords.compactMap { $0.toEventRecord() }
        let injected     = EventRecord(eventType: eventType, timestamp: .now)
        let counts       = DailyStats.counts(from: eventRecords + [injected], for: .now)
        WidgetDataBridge.write(counts: counts)
        WidgetDataBridge.requestWidgetTimelineReload()

        // 4. CloudKit push (non-blocking background Task)
        guard !familyId.isEmpty, !userId.isEmpty else { return }
        Task {
            guard cloudKit.isAvailable else { return }
            do {
                let ck = try await cloudKit.pushEvent(
                    eventTypeRaw: record.eventTypeRaw,
                    timestamp: record.timestamp,
                    familyId: familyId,
                    userId: userId
                )
                record.cloudKitRecordName = ck.recordID.recordName
                record.isSynced = true
            } catch {
                // isSynced stays false → EventSyncService.pushPending retries on next launch
            }
        }
    }

    func todayCounts(from records: [BabyEventRecord]) -> DailyCounts {
        let eventRecords = records.compactMap { $0.toEventRecord() }
        return DailyStats.counts(from: eventRecords, for: .now)
    }

    // MARK: - Private

    private func loadCachedEnemies() async {
        // Load from SwiftData cache
        let descriptor = FetchDescriptor<CachedEnemyRecord>()
        if let cached = try? modelContext.fetch(descriptor) {
            let templates = cached.compactMap { $0.toTemplate() }
            if !templates.isEmpty { availableEnemyTemplates = templates }
        }

        // Refresh from CloudKit in background (non-blocking)
        Task {
            guard cloudKit.isAvailable else { return }
            let sync = EventSyncService(cloudKit: cloudKit)
            try? await sync.refreshEnemies(into: modelContext)
            if let fresh = try? modelContext.fetch(FetchDescriptor<CachedEnemyRecord>()) {
                let templates = fresh.compactMap { $0.toTemplate() }
                if !templates.isEmpty { availableEnemyTemplates = templates }
            }
        }
    }
}
