import CloudKit
import Foundation
import OSLog
import SwiftData

private let vmlog = Logger(subsystem: "productions.jocarium.judar", category: "BattleViewModel")

@Observable
@MainActor
final class BattleViewModel {
    private(set) var battleState: BattleState
    private let modelContext: ModelContext
    private let cloudKit: CloudKitSyncService
    private let syncService: EventSyncService

    // Populated from CachedEnemyRecord (CloudKit) on init; falls back to EnemyRoster.all
    private var availableEnemyTemplates: [EnemyTemplate] = []

    init(modelContext: ModelContext, cloudKit: CloudKitSyncService) {
        self.modelContext = modelContext
        self.cloudKit = cloudKit
        self.syncService = EventSyncService(cloudKit: cloudKit)

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

    func logEvent(
        _ eventType: EventType,
        amount: Int = 0,
        familyId: String,
        userId: String
    ) {
        // 1. Persist locally (Shell)
        let record = BabyEventRecord(eventType: eventType, amount: amount)
        record.familyId = familyId
        modelContext.insert(record)

        // 2. Pure battle resolution (Core)
        let (newState, _) = BattleLogic.resolveAttack(
            eventType: eventType,
            amount: amount,
            state: battleState,
            availableEnemies: availableEnemyTemplates,
            randomSource: .live
        )
        battleState = newState

        // 3. Persist battle progress (local + CloudKit background)
        saveProgress(familyId: familyId, userId: userId)

        // 4. Widget sync
        WidgetDataBridge.requestWidgetTimelineReload()

        // 5. CloudKit push (non-blocking background Task)
        guard !familyId.isEmpty, !userId.isEmpty else {
            vmlog.warning("⚠️ logEvent skip CK push — familyId or userId empty")
            return
        }
        Task {
            guard cloudKit.isAvailable else {
                vmlog.warning("⚠️ logEvent skip CK push — CloudKit unavailable")
                return
            }
            vmlog.debug("  → CK push start type=\(record.eventTypeRaw, privacy: .public) ts=\(record.timestamp)")
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
                vmlog.debug("  ✅ CK push ok recordName=\(ck.recordID.recordName, privacy: .public)")
            } catch {
                record.syncErrorRaw = error.localizedDescription
                vmlog.error("  ❌ CK push failed type=\(record.eventTypeRaw, privacy: .public) error=\(error, privacy: .public)")
            }
            // Widget reads CloudKit as source of truth — re-sync now that the push landed (or failed).
            WidgetDataBridge.requestWidgetTimelineReload()
        }
    }

    func retrySync(record: BabyEventRecord, familyId: String, userId: String)
        async
    {
        record.syncErrorRaw = ""
        await syncService.pushPending(
            records: [record],
            familyId: familyId,
            userId: userId
        )
    }

    func pushAllPending(
        records: [BabyEventRecord],
        familyId: String,
        userId: String
    ) async {
        await syncService.pushPending(
            records: records,
            familyId: familyId,
            userId: userId
        )
    }

    /// Restore battle state from CloudKit (falling back to local SwiftData cache).
    /// Call once in ContentView.bootServices() after profile is loaded.
    func restoreProgress(familyId: String, userId: String) async {
        // Ensure templates are available (loadCachedEnemies may still be running)
        if availableEnemyTemplates.isEmpty {
            if let cached = try? modelContext.fetch(
                FetchDescriptor<CachedEnemyRecord>()
            ) {
                let templates = cached.compactMap { $0.toTemplate() }
                if !templates.isEmpty { availableEnemyTemplates = templates }
            }
        }

        // Try CloudKit first (authoritative, shared across family reinstalls)
        if cloudKit.isAvailable, !familyId.isEmpty,
            let ck = try? await cloudKit.fetchBattleProgress(familyId: familyId)
        {
            applyProgress(
                enemyName: (ck[BattleProgressF.enemyName] as? String) ?? "",
                enemyCurrentHP: (ck[BattleProgressF.enemyCurrentHP] as? Int)
                    ?? (ck[BattleProgressF.enemyCurrentHP] as? NSNumber)?
                    .intValue ?? 0,
                killStreak: (ck[BattleProgressF.killStreak] as? Int)
                    ?? (ck[BattleProgressF.killStreak] as? NSNumber)?.intValue
                    ?? 0,
                partyHP: (ck[BattleProgressF.partyHP] as? Int)
                    ?? (ck[BattleProgressF.partyHP] as? NSNumber)?.intValue
                    ?? BattleState.initialPartyHP
            )
            return
        }

        // Fallback: local SwiftData (survives app background, not reinstall)
        if let local =
            (try? modelContext.fetch(FetchDescriptor<CachedBattleProgress>()))?
            .first,
            !local.enemyName.isEmpty
        {
            applyProgress(
                enemyName: local.enemyName,
                enemyCurrentHP: local.enemyCurrentHP,
                killStreak: local.killStreak,
                partyHP: local.partyHP
            )
        }
    }

    // MARK: - Private

    private func applyProgress(
        enemyName: String,
        enemyCurrentHP: Int,
        killStreak: Int,
        partyHP: Int
    ) {
        guard enemyCurrentHP > 0 else { return }  // 0 HP means battle resolved; keep fresh state

        let pool =
            availableEnemyTemplates.isEmpty
            ? EnemyRoster.all : availableEnemyTemplates
        guard let template = pool.first(where: { $0.name == enemyName }) else {
            return
        }

        var enemy = Enemy(template: template)
        enemy.currentHP = min(enemyCurrentHP, template.maxHP)

        battleState = BattleState(
            enemy: enemy,
            partyHP: max(1, partyHP),
            killStreak: killStreak,
            battleLog: [
                "> *** 冒険を再開 ***",
                "> \(template.name) [HP:\(enemy.currentHP)/\(template.maxHP)]",
                "> 連続討伐 \(killStreak)",
            ]
        )
    }

    private func saveProgress(familyId: String, userId: String) {
        // Local SwiftData (always, no network required)
        let local: CachedBattleProgress
        if let existing =
            (try? modelContext.fetch(FetchDescriptor<CachedBattleProgress>()))?
            .first
        {
            local = existing
        } else {
            local = CachedBattleProgress()
            modelContext.insert(local)
        }
        local.enemyName = battleState.enemy.template.name
        local.enemyCurrentHP = battleState.enemy.currentHP
        local.killStreak = battleState.killStreak
        local.partyHP = battleState.partyHP
        local.updatedAt = .now

        // CloudKit (non-blocking; captures values before entering async context)
        guard cloudKit.isAvailable, !familyId.isEmpty, !userId.isEmpty else {
            return
        }
        let name = battleState.enemy.template.name
        let hp = battleState.enemy.currentHP
        let ks = battleState.killStreak
        let php = battleState.partyHP
        Task {
            try? await cloudKit.saveBattleProgress(
                enemyName: name,
                enemyCurrentHP: hp,
                killStreak: ks,
                partyHP: php,
                familyId: familyId,
                userId: userId
            )
        }
    }

    private func loadCachedEnemies() async {
        // Load from SwiftData cache
        if let cached = try? modelContext.fetch(
            FetchDescriptor<CachedEnemyRecord>()
        ) {
            let templates = cached.compactMap { $0.toTemplate() }
            if !templates.isEmpty { availableEnemyTemplates = templates }
        }

        // Refresh from CloudKit in background (non-blocking)
        Task {
            guard cloudKit.isAvailable else { return }
            try? await syncService.refreshEnemies(into: modelContext)
            if let fresh = try? modelContext.fetch(
                FetchDescriptor<CachedEnemyRecord>()
            ) {
                let templates = fresh.compactMap { $0.toTemplate() }
                if !templates.isEmpty { availableEnemyTemplates = templates }
            }
        }
    }
}
