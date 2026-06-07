import Testing
import Foundation
@testable import judar

// MARK: - Shared test fixtures

// nextDouble=0.0: accuracy check (rng > accuracy) always false → hit
// nextInt=0: damage spread always lowest bound
private let alwaysHit  = RandomSource(nextDouble: { 0.0 }, nextInt: { _ in 0 })
// nextDouble=1.0: accuracy check always true → miss
private let alwaysMiss = RandomSource(nextDouble: { 1.0 }, nextInt: { _ in 0 })

private func makeState(
    template: EnemyTemplate = EnemyRoster.firstEnemy().template,
    partyHP: Int = BattleState.initialPartyHP,
    killStreak: Int = 0,
    log: [String] = []
) -> BattleState {
    BattleState(enemy: Enemy(template: template), partyHP: partyHP, killStreak: killStreak, battleLog: log)
}

// 1-HP, no-resist, 0-counter: useful for heal tests (enemy dies → no counter fires)
private let tinyCritter = EnemyTemplate(name: "弱", maxHP: 1, resistances: [], weaknesses: [], attackPower: 1, asciiArt: "")

// Resists physical + magical + heal — any player attack deals 0 damage
private let allResistBoss = EnemyRoster.all.first { $0.resistances == [.physical, .magical, .heal] }!

// ────────────────────────────────────────────────────────────────────────────
// MARK: - DailyCounts
// ────────────────────────────────────────────────────────────────────────────

@Suite("DailyCounts") struct DailyCountsTests {

    @Test func zeroInitialized() {
        let c = DailyCounts()
        #expect(c.poop == 0 && c.pee == 0 && c.breastfeed == 0 && c.formula == 0)
        #expect(c.total == 0)
    }

    @Test func subscriptGetReturnsCorrectField() {
        let c = DailyCounts(poop: 3, pee: 5, breastfeed: 1, formula: 2)
        #expect(c[.poop]       == 3)
        #expect(c[.pee]        == 5)
        #expect(c[.breastfeed] == 1)
        #expect(c[.formula]    == 2)
    }

    @Test func subscriptSetMutatesCorrectField() {
        var c = DailyCounts()
        c[.poop] = 7; c[.pee] = 4; c[.breastfeed] = 2; c[.formula] = 1
        #expect(c.poop == 7 && c.pee == 4 && c.breastfeed == 2 && c.formula == 1)
    }

    @Test func totalIsSum() {
        let c = DailyCounts(poop: 2, pee: 3, breastfeed: 4, formula: 1)
        #expect(c.total == 10)
    }

    @Test func equatableEqual() {
        #expect(DailyCounts(poop: 1) == DailyCounts(poop: 1))
    }

    @Test func equatableNotEqual() {
        #expect(DailyCounts(poop: 1) != DailyCounts(poop: 2))
    }

    @Test func codableRoundtrip() throws {
        let original = DailyCounts(poop: 3, pee: 7, breastfeed: 2, formula: 5)
        let data     = try JSONEncoder().encode(original)
        let decoded  = try JSONDecoder().decode(DailyCounts.self, from: data)
        #expect(decoded == original)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MARK: - EventType
// ────────────────────────────────────────────────────────────────────────────

@Suite("EventType") struct EventTypeTests {

    @Test func rawValues() {
        #expect(EventType.poop.rawValue       == "poop")
        #expect(EventType.pee.rawValue        == "pee")
        #expect(EventType.breastfeed.rawValue == "breastfeed")
        #expect(EventType.formula.rawValue    == "formula")
    }

    @Test func attackTypeMapping() {
        #expect(EventType.poop.attackType       == .physical)
        #expect(EventType.pee.attackType        == .magical)
        #expect(EventType.breastfeed.attackType == .heal)
        #expect(EventType.formula.attackType    == .heal)
    }

    @Test func allCasesCountIs4() {
        #expect(EventType.allCases.count == 4)
    }

    @Test func displayNameNonEmpty() {
        for et in EventType.allCases {
            #expect(!et.displayName.isEmpty)
        }
    }

    @Test func initFromRawValue() {
        #expect(EventType(rawValue: "poop") == .poop)
        #expect(EventType(rawValue: "unknown") == nil)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MARK: - AttackType
// ────────────────────────────────────────────────────────────────────────────

@Suite("AttackType") struct AttackTypeTests {

    @Test func rawValues() {
        #expect(AttackType.physical.rawValue == "physical")
        #expect(AttackType.magical.rawValue  == "magical")
        #expect(AttackType.heal.rawValue     == "heal")
    }

    @Test func usableInSet() {
        let s: Set<AttackType> = [.physical, .magical, .physical]
        #expect(s.count == 2)
    }

    @Test func codableRoundtrip() throws {
        let original: [AttackType] = [.physical, .magical, .heal]
        let data    = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([AttackType].self, from: data)
        #expect(decoded == original)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MARK: - PartyMember
// ────────────────────────────────────────────────────────────────────────────

@Suite("PartyMember") struct PartyMemberTests {

    @Test func allHas4Members() {
        #expect(PartyMember.all.count == 4)
    }

    @Test func eachEventTypeMapsToUniqueMember() {
        let names = EventType.allCases.map { PartyMember.member(for: $0).name }
        #expect(Set(names).count == 4)
    }

    @Test func poop_physicalWarrior() {
        let m = PartyMember.member(for: .poop)
        #expect(m.name == "ブリ丸")
        #expect(m.baseDamage == 15)
        #expect(m.accuracy   == 0.75)
        #expect(m.eventType.attackType == .physical)
    }

    @Test func pee_magicUser() {
        let m = PartyMember.member(for: .pee)
        #expect(m.name == "オシ魔神")
        #expect(m.baseDamage == 12)
        #expect(m.accuracy   == 0.90)
        #expect(m.eventType.attackType == .magical)
    }

    @Test func breastfeed_highAccuracyHealer() {
        let m = PartyMember.member(for: .breastfeed)
        #expect(m.eventType.attackType == .heal)
        #expect(m.accuracy >= 0.90)
    }

    @Test func formula_highAccuracyHealer() {
        let m = PartyMember.member(for: .formula)
        #expect(m.eventType.attackType == .heal)
        #expect(m.accuracy >= 0.90)
    }

    @Test func eventTypeExtensionMatchesMember() {
        for et in EventType.allCases {
            #expect(et.partyMember == PartyMember.member(for: et))
        }
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MARK: - EnemyRoster
// ────────────────────────────────────────────────────────────────────────────

@Suite("EnemyRoster") struct EnemyRosterTests {

    @Test func allHas8Templates() {
        #expect(EnemyRoster.all.count == 8)
    }

    @Test func allNamesAreUnique() {
        let names = EnemyRoster.all.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test func allTemplatesHavePositiveStats() {
        for t in EnemyRoster.all {
            #expect(t.maxHP > 0)
            #expect(t.attackPower > 0)
        }
    }

    @Test func firstEnemyIsGepuryu() {
        let e = EnemyRoster.firstEnemy()
        #expect(e.template.name == "げっぷ竜")
    }

    @Test func firstEnemyHasNoResistancesOrWeaknesses() {
        let e = EnemyRoster.firstEnemy()
        #expect(e.template.resistances.isEmpty)
        #expect(e.template.weaknesses.isEmpty)
    }

    @Test func firstEnemyStartsAtMaxHP() {
        let e = EnemyRoster.firstEnemy()
        #expect(e.currentHP == e.template.maxHP)
    }

    @Test func randomTemplate_neverReturnsExcludedName() {
        let excluded = EnemyRoster.all[0].name
        for seed: UInt64 in [1, 42, 999, 12345, 99999] {
            let t = EnemyRoster.randomTemplate(excluding: excluded, randomSource: .seeded(seed))
            #expect(t.name != excluded)
        }
    }

    @Test func randomTemplate_emptyPoolFallsBackToAll() {
        let t = EnemyRoster.randomTemplate(from: [], excluding: nil, randomSource: alwaysHit)
        #expect(EnemyRoster.all.contains(t))
    }

    @Test func randomTemplate_singleItemExcluded_returnsItAsOnlyCandidate() {
        // When all candidates are excluded, finalPool falls back to the full source (single item).
        let single = EnemyRoster.all[0]
        let t = EnemyRoster.randomTemplate(from: [single], excluding: single.name, randomSource: alwaysHit)
        #expect(t == single)
    }

    @Test func randomTemplate_deterministic() {
        let seed: UInt64 = 7
        let t1 = EnemyRoster.randomTemplate(from: EnemyRoster.all, excluding: nil, randomSource: .seeded(seed))
        let t2 = EnemyRoster.randomTemplate(from: EnemyRoster.all, excluding: nil, randomSource: .seeded(seed))
        #expect(t1 == t2)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MARK: - BattleLogic.computePlayerDamage
// ────────────────────────────────────────────────────────────────────────────

@Suite("BattleLogic.computePlayerDamage") struct ComputePlayerDamageTests {

    @Test func resist_alwaysZero() {
        for et in EventType.allCases {
            let d = BattleLogic.computePlayerDamage(
                member: .member(for: et), isResisted: true, isWeakness: false, randomSource: alwaysHit)
            #expect(d == 0)
        }
    }

    @Test func miss_returnsZero() {
        for et in EventType.allCases {
            let d = BattleLogic.computePlayerDamage(
                member: .member(for: et), isResisted: false, isWeakness: false, randomSource: alwaysMiss)
            #expect(d == 0)
        }
    }

    @Test func hit_returnsPositiveDamage() {
        for et in EventType.allCases {
            let d = BattleLogic.computePlayerDamage(
                member: .member(for: et), isResisted: false, isWeakness: false, randomSource: alwaysHit)
            #expect(d >= 1)
        }
    }

    @Test func weakness_dealsMoreThanNeutral() {
        let m = PartyMember.member(for: .pee)
        let neutral  = BattleLogic.computePlayerDamage(member: m, isResisted: false, isWeakness: false, randomSource: alwaysHit)
        let weakness = BattleLogic.computePlayerDamage(member: m, isResisted: false, isWeakness: true,  randomSource: alwaysHit)
        #expect(weakness > neutral)
    }

    @Test func weakness_damageIs1_5xNeutral() {
        // alwaysHit with nextInt=0 gives deterministic base damage → exact 1.5x check
        let m = PartyMember.member(for: .poop)
        let neutral  = Double(BattleLogic.computePlayerDamage(member: m, isResisted: false, isWeakness: false, randomSource: alwaysHit))
        let weakness = Double(BattleLogic.computePlayerDamage(member: m, isResisted: false, isWeakness: true,  randomSource: alwaysHit))
        #expect(weakness == neutral * 1.5)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MARK: - BattleLogic.resolveAttack
// ────────────────────────────────────────────────────────────────────────────

@Suite("BattleLogic.resolveAttack") struct ResolveAttackTests {

    // ── Resist / Weakness ────────────────────────────────────────────────────

    @Test func allResistEnemy_anyAttack_dealsZero() {
        for et in EventType.allCases {
            let state = makeState(template: allResistBoss)
            let (_, result) = BattleLogic.resolveAttack(eventType: et, state: state, randomSource: alwaysHit)
            #expect(result.isResisted)
            #expect(result.playerDamage == 0)
        }
    }

    @Test func magicalWeaknessEnemy_pee_flagsIsWeakness() {
        // 眠気の悪魔 is weak to magical
        let weakToMagic = EnemyRoster.all.first { $0.weaknesses.contains(.magical) }!
        let state = makeState(template: weakToMagic)
        let (_, result) = BattleLogic.resolveAttack(eventType: .pee, state: state, randomSource: alwaysHit)
        #expect(result.isWeakness)
        #expect(result.playerDamage > 0)
    }

    @Test func physicalHit_nonResistEnemy_dealsPositiveDamage() {
        // 夜泣き鬼 resists magical (not physical) — physical hits land
        let resistMagic = EnemyRoster.all.first { $0.resistances.contains(.magical) && !$0.resistances.contains(.physical) }!
        let state = makeState(template: resistMagic)
        let (_, result) = BattleLogic.resolveAttack(eventType: .poop, state: state, randomSource: alwaysHit)
        #expect(!result.isResisted)
        #expect(result.playerDamage > 0)
    }

    // ── Heal type ────────────────────────────────────────────────────────────

    @Test func heal_nonResist_increasesPartyHP() {
        // Use tinyCritter (1 HP, no resist) so heal kills it and no counter fires.
        // breastfeed: playerDamage=7, healAmount=3, enemy HP reduced by 2 → dies.
        let state = BattleState(enemy: Enemy(template: tinyCritter), partyHP: 50, killStreak: 0, battleLog: [])
        let (newState, _) = BattleLogic.resolveAttack(eventType: .breastfeed, state: state, randomSource: alwaysHit)
        #expect(newState.partyHP > 50)
    }

    @Test func heal_cannotExceedInitialPartyHP() {
        let state = BattleState(enemy: Enemy(template: tinyCritter), partyHP: BattleState.initialPartyHP, killStreak: 0, battleLog: [])
        let (newState, _) = BattleLogic.resolveAttack(eventType: .breastfeed, state: state, randomSource: alwaysHit)
        #expect(newState.partyHP == BattleState.initialPartyHP)
    }

    @Test func heal_resisted_playerDamageIsZero() {
        // おむつ妖怪 resists .heal → computePlayerDamage returns 0 → no healing
        let resistHeal = EnemyRoster.all.first { $0.resistances.contains(.heal) }!
        let state = makeState(template: resistHeal)
        let (_, result) = BattleLogic.resolveAttack(eventType: .breastfeed, state: state, randomSource: alwaysHit)
        #expect(result.isResisted)
        #expect(result.playerDamage == 0)
    }

    @Test func heal_resisted_enemyHPUnchanged() {
        let resistHeal = EnemyRoster.all.first { $0.resistances.contains(.heal) }!
        let state = makeState(template: resistHeal)
        let (newState, result) = BattleLogic.resolveAttack(eventType: .breastfeed, state: state, randomSource: alwaysHit)
        #expect(result.isResisted)
        #expect(newState.enemy.currentHP == state.enemy.currentHP)
    }

    // ── Miss ─────────────────────────────────────────────────────────────────

    @Test func miss_enemyHPUnchanged() {
        let state = makeState()
        let (newState, result) = BattleLogic.resolveAttack(eventType: .poop, state: state, randomSource: alwaysMiss)
        #expect(!result.enemyDefeated)
        #expect(newState.enemy.currentHP == state.enemy.currentHP)
    }

    // ── Counter-attack ───────────────────────────────────────────────────────

    @Test func counterAttack_reducesPartyHP() {
        // alwaysMiss: player misses → enemy alive → counter fires
        let state = makeState()
        let (newState, _) = BattleLogic.resolveAttack(eventType: .poop, state: state, randomSource: alwaysMiss)
        #expect(newState.partyHP < state.partyHP)
    }

    @Test func counterAttack_doesNotFireWhenEnemyDefeated() {
        // tinyCritter (1 HP) + alwaysHit: enemy dies, no counter.
        // PartyHP at max stays at max (or increases from heal — not relevant here for poop).
        let state = makeState(template: tinyCritter)
        let (newState, result) = BattleLogic.resolveAttack(eventType: .poop, state: state, randomSource: alwaysHit)
        #expect(result.enemyDefeated)
        #expect(result.enemyCounterDamage == 0)
        #expect(newState.partyHP == state.partyHP)
    }

    // ── Soft-defeat floor ────────────────────────────────────────────────────

    @Test func partyHP_dropsToZero_recoversTo30() {
        // コリック悪霊 resists all → player always deals 0 → counter fires.
        // With partyHP=1, counterDamage ≥ 1 → partyHP would go to 0 → floored to 30.
        let state = makeState(template: allResistBoss, partyHP: 1)
        let (newState, _) = BattleLogic.resolveAttack(eventType: .poop, state: state, randomSource: alwaysHit)
        #expect(newState.partyHP == 30)
    }

    // ── Enemy defeat ─────────────────────────────────────────────────────────

    @Test func enemyDefeat_incrementsKillStreak() {
        let state = makeState(template: tinyCritter)
        let (newState, result) = BattleLogic.resolveAttack(eventType: .poop, state: state, randomSource: alwaysHit)
        #expect(result.enemyDefeated)
        #expect(newState.killStreak == state.killStreak + 1)
    }

    @Test func enemyDefeat_spawnsFreshEnemy() {
        let state = makeState(template: tinyCritter)
        let (newState, result) = BattleLogic.resolveAttack(eventType: .poop, state: state, randomSource: alwaysHit)
        #expect(result.enemyDefeated)
        // New enemy starts at full HP.
        #expect(newState.enemy.currentHP == newState.enemy.template.maxHP)
    }

    @Test func enemyDefeat_withCloudKitPool_spawnsFromPool() {
        let cloudEnemy = EnemyTemplate(name: "クラウド敵", maxHP: 99, resistances: [], weaknesses: [], attackPower: 3, asciiArt: "")
        let state = makeState(template: tinyCritter)
        let (newState, result) = BattleLogic.resolveAttack(
            eventType: .poop, state: state, availableEnemies: [cloudEnemy], randomSource: alwaysHit)
        #expect(result.enemyDefeated)
        #expect(newState.enemy.template.name == "クラウド敵")
    }

    @Test func enemyDefeat_emptyCloudKitPool_fallsBackToRoster() {
        let state = makeState(template: tinyCritter)
        let (newState, result) = BattleLogic.resolveAttack(
            eventType: .poop, state: state, availableEnemies: [], randomSource: alwaysHit)
        #expect(result.enemyDefeated)
        #expect(EnemyRoster.all.contains(newState.enemy.template))
    }

    // ── Battle log ───────────────────────────────────────────────────────────

    @Test func battleLog_neverExceedsCap() {
        // Start full; keep firing and verify cap holds.
        var state = makeState(log: Array(repeating: "> 行", count: BattleState.logCap))
        for et in EventType.allCases {
            let (newState, _) = BattleLogic.resolveAttack(eventType: et, state: state, randomSource: alwaysHit)
            #expect(newState.battleLog.count <= BattleState.logCap)
            state = newState
        }
    }

    @Test func battleLog_containsAttackerName() {
        for et in EventType.allCases {
            let state = makeState()
            let (newState, _) = BattleLogic.resolveAttack(eventType: et, state: state, randomSource: alwaysHit)
            let name = PartyMember.member(for: et).name
            #expect(newState.battleLog.contains { $0.contains(name) })
        }
    }

    // ── Determinism ──────────────────────────────────────────────────────────

    @Test func seededRNG_fullyDeterministic() {
        let seed: UInt64 = 42
        let state = makeState()
        let (s1, r1) = BattleLogic.resolveAttack(eventType: .pee, state: state, randomSource: .seeded(seed))
        let (s2, r2) = BattleLogic.resolveAttack(eventType: .pee, state: state, randomSource: .seeded(seed))
        #expect(s1 == s2)
        #expect(r1 == r2)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MARK: - DailyStats
// ────────────────────────────────────────────────────────────────────────────

@Suite("DailyStats") struct DailyStatsTests {

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "ja_JP")
        return c
    }
    private var today: Date     { cal.startOfDay(for: Date()) }
    private var yesterday: Date { cal.date(byAdding: .day, value: -1, to: today)! }

    private func record(_ type: EventType, daysAgo: Int = 0, hour: Int = 12) -> EventRecord {
        let base = cal.date(byAdding: .day, value: -daysAgo, to: today)!
        let ts   = cal.date(byAdding: .hour, value: hour, to: base)!
        return EventRecord(eventType: type, timestamp: ts)
    }

    @Test func counts_emptyRecords_allZero() {
        let c = DailyStats.counts(from: [], for: today, calendar: cal)
        #expect(c == DailyCounts())
    }

    @Test func counts_filtersToTargetDay() {
        let records = [
            record(.poop, daysAgo: 0),
            record(.poop, daysAgo: 0),
            record(.poop, daysAgo: 1),  // yesterday — must not count
        ]
        let c = DailyStats.counts(from: records, for: today, calendar: cal)
        #expect(c.poop == 2)
        #expect(c.total == 2)
    }

    @Test func counts_multipleTypes() {
        let records = [
            record(.poop), record(.poop),
            record(.pee),
            record(.breastfeed), record(.breastfeed), record(.breastfeed),
            record(.formula),
        ]
        let c = DailyStats.counts(from: records, for: today, calendar: cal)
        #expect(c.poop == 2 && c.pee == 1 && c.breastfeed == 3 && c.formula == 1)
        #expect(c.total == 7)
    }

    @Test func counts_forYesterday_excludesToday() {
        let records = [
            record(.pee, daysAgo: 1),
            record(.pee, daysAgo: 0),  // today — must not count
        ]
        let c = DailyStats.counts(from: records, for: yesterday, calendar: cal)
        #expect(c.pee == 1)
        #expect(c.poop == 0)
    }

    @Test func groupByDay_emptyInput_emptyOutput() {
        #expect(DailyStats.groupByDay(records: [], calendar: cal).isEmpty)
    }

    @Test func groupByDay_singleDay_oneGroup() {
        let records = [record(.poop), record(.pee), record(.breastfeed)]
        let groups  = DailyStats.groupByDay(records: records, calendar: cal)
        #expect(groups.count == 1)
        #expect(groups[0].records.count == 3)
    }

    @Test func groupByDay_daysOrderedNewestFirst() {
        let records = [
            record(.poop, daysAgo: 0),
            record(.pee,  daysAgo: 1),
            record(.poop, daysAgo: 2),
        ]
        let groups = DailyStats.groupByDay(records: records, calendar: cal)
        #expect(groups.count == 3)
        #expect(groups[0].day >= groups[1].day)
        #expect(groups[1].day >= groups[2].day)
    }

    @Test func groupByDay_withinDay_recordsNewestFirst() {
        let morning = cal.date(byAdding: .hour, value: 8,  to: today)!
        let evening = cal.date(byAdding: .hour, value: 20, to: today)!
        let records = [
            EventRecord(eventType: .poop, timestamp: morning),
            EventRecord(eventType: .pee,  timestamp: evening),
        ]
        let groups = DailyStats.groupByDay(records: records, calendar: cal)
        #expect(groups.count == 1)
        #expect(groups[0].records[0].timestamp >= groups[0].records[1].timestamp)
    }

    @Test func groupByDay_totalRecordCountPreserved() {
        let records = (0..<5).map { i in record(.poop, daysAgo: i % 3) }
        let groups  = DailyStats.groupByDay(records: records, calendar: cal)
        let total   = groups.reduce(0) { $0 + $1.records.count }
        #expect(total == records.count)
    }

    @Test func groupByDay_dayKeyIsStartOfDay() {
        let ts = cal.date(byAdding: .hour, value: 15, to: today)!
        let records = [EventRecord(eventType: .poop, timestamp: ts)]
        let groups  = DailyStats.groupByDay(records: records, calendar: cal)
        #expect(groups[0].day == today)
    }
}
