import Foundation

// MARK: - RandomSource

struct RandomSource {
    let nextDouble: () -> Double  // returns 0.0 ..< 1.0
    let nextInt: (Int) -> Int     // returns 0 ..< n

    static var live: RandomSource {
        RandomSource(
            nextDouble: { Double.random(in: 0.0..<1.0) },
            nextInt: { n in Int.random(in: 0..<max(1, n)) }
        )
    }

    // Deterministic source for unit tests — wraps a simple xorshift PRNG
    static func seeded(_ seed: UInt64) -> RandomSource {
        let rng = SeededRNG(seed: seed)
        return RandomSource(
            nextDouble: { rng.nextDouble() },
            nextInt: { n in rng.nextInt(n) }
        )
    }
}

// Thread-unsafe; intended for single-actor (MainActor) test use only
private final class SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed  // xorshift requires non-zero state
    }

    private func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    func nextDouble() -> Double {
        let bits = next()
        return Double(bits >> 11) / Double(1 << 53)
    }

    func nextInt(_ n: Int) -> Int {
        guard n > 1 else { return 0 }
        return Int(next() % UInt64(n))
    }
}

// MARK: - BattleLogic

enum BattleLogic {

    // Main entry point. Pure: all randomness + enemy pool injected.
    // availableEnemies: CloudKit-cached templates; falls back to EnemyRoster.all when empty.
    static func resolveAttack(
        eventType: EventType,
        state: BattleState,
        availableEnemies: [EnemyTemplate] = [],
        randomSource: RandomSource
    ) -> (newState: BattleState, result: AttackResult) {

        let member = PartyMember.member(for: eventType)
        var enemy = state.enemy
        var partyHP = state.partyHP
        var killStreak = state.killStreak
        var logLines: [String] = []

        // --- Player action ---
        let attackType = member.eventType.attackType
        let isResisted = enemy.template.resistances.contains(attackType)
        let isWeakness = enemy.template.weaknesses.contains(attackType)
        let playerDamage = computePlayerDamage(
            member: member,
            isResisted: isResisted,
            isWeakness: isWeakness,
            randomSource: randomSource
        )

        logLines.append("> \(member.name) の こうげき！")

        if isResisted {
            logLines.append("> \(enemy.template.name) には きかない！")
        } else if playerDamage == 0 {
            logLines.append("> ミス！")
        } else if isWeakness {
            logLines.append("> ウィーク！ \(enemy.template.name) に \(playerDamage) ダメージ！")
        } else {
            logLines.append("> \(enemy.template.name) に \(playerDamage) ダメージ！")
        }

        // Apply player damage; heal types also recover party HP
        if attackType == .heal {
            let healAmount = max(0, playerDamage / 2)
            partyHP = min(BattleState.initialPartyHP, partyHP + healAmount)
            if !isResisted && playerDamage > 0 {
                enemy.currentHP = max(0, enemy.currentHP - max(1, playerDamage / 3))
            }
        } else {
            enemy.currentHP = max(0, enemy.currentHP - playerDamage)
        }

        // --- Enemy counter-attack or defeat ---
        let enemyDefeated = enemy.isDead
        var counterDamage = 0

        if enemyDefeated {
            killStreak += 1
            logLines.append("> \(enemy.template.name) を たおした！")
            logLines.append("> *** 連続討伐 \(killStreak) ***")
            // Spawn next enemy from CloudKit pool (or hardcoded fallback)
            let nextTemplate = EnemyRoster.randomTemplate(
                from: availableEnemies,
                excluding: enemy.template.name,
                randomSource: randomSource
            )
            enemy = Enemy(template: nextTemplate)
            logLines.append("> あたらしい てきが あらわれた！")
            logLines.append("> [\(enemy.template.name) HP:\(enemy.template.maxHP)]")
        } else {
            counterDamage = computeCounterDamage(enemy: enemy, randomSource: randomSource)
            partyHP = max(0, partyHP - counterDamage)
            logLines.append("> \(enemy.template.name) の はんげき！")
            logLines.append("> パーティ に \(counterDamage) ダメージ！")

            if partyHP <= 0 {
                // Soft-defeat: recover to 30 so the game continues
                partyHP = 30
                logLines.append("> ピンチ！ しかし おやは あきらめない！")
            }
        }

        let result = AttackResult(
            playerDamage: playerDamage,
            enemyCounterDamage: counterDamage,
            isResisted: isResisted,
            isWeakness: isWeakness,
            enemyDefeated: enemyDefeated,
            logLines: logLines
        )

        let fullLog = state.battleLog + logLines
        let cappedLog = Array(fullLog.suffix(BattleState.logCap))

        let newState = BattleState(
            enemy: enemy,
            partyHP: partyHP,
            killStreak: killStreak,
            battleLog: cappedLog
        )

        return (newState, result)
    }

    // MARK: - Private helpers (internal visibility for testing)

    static func computePlayerDamage(
        member: PartyMember,
        isResisted: Bool,
        isWeakness: Bool,
        randomSource: RandomSource
    ) -> Int {
        if isResisted { return 0 }
        // Accuracy check
        if randomSource.nextDouble() > member.accuracy { return 0 }
        // Damage with ±variance
        let spread = max(1, member.baseDamage / 4)
        let base = member.baseDamage - spread / 2 + randomSource.nextInt(spread)
        let damage = isWeakness ? Int(Double(base) * 1.5) : base
        return max(1, damage)
    }

    static func computeCounterDamage(
        enemy: Enemy,
        randomSource: RandomSource
    ) -> Int {
        let base = enemy.template.attackPower
        let spread = max(1, base / 3)
        return max(1, base - spread / 2 + randomSource.nextInt(spread))
    }
}
