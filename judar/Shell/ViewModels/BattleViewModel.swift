import SwiftUI
import SwiftData

@Observable
@MainActor
final class BattleViewModel {
    private(set) var battleState: BattleState
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
    }

    // Called by the 4 input buttons. allRecords from @Query passed in so VM stays stateless on DB reads.
    func logEvent(_ eventType: EventType, allRecords: [BabyEventRecord]) {
        // 1. Persist (Shell)
        modelContext.insert(BabyEventRecord(eventType: eventType))

        // 2. Pure battle resolution (Core)
        let (newState, _) = BattleLogic.resolveAttack(
            eventType: eventType,
            state: battleState,
            randomSource: .live
        )
        battleState = newState

        // 3. Sync widget (Shell)
        let eventRecords = allRecords.compactMap { $0.toEventRecord() }
        let injected = EventRecord(eventType: eventType, timestamp: .now)
        let counts = DailyStats.counts(from: eventRecords + [injected], for: .now)
        WidgetDataBridge.write(counts: counts)
        WidgetDataBridge.requestWidgetTimelineReload()
    }

    // Recomputes today's counts from the @Query records (called by view on render)
    func todayCounts(from records: [BabyEventRecord]) -> DailyCounts {
        let eventRecords = records.compactMap { $0.toEventRecord() }
        return DailyStats.counts(from: eventRecords, for: .now)
    }
}
