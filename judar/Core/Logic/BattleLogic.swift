import Foundation

// MARK: - RandomSource

struct RandomSource {
    let nextDouble: () -> Double  // returns 0.0 ..< 1.0
    let nextInt: (Int) -> Int  // returns 0 ..< n

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
    static func resolveAttack(
        eventType: EventType,
        amount: Int = 0,
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
        let isCritical = randomSource.nextDouble() < 0.15  // 15% crit chance, ignores resist

        let playerDamage = computePlayerDamage(
            member: member,
            isResisted: isResisted,
            isWeakness: isWeakness,
            isCritical: isCritical,
            randomSource: randomSource
        )

        // Action label — show ml amount for milk-measurement events
        let actionLabel = ((eventType == .formula || eventType == .pumpedMilk) && amount > 0)
            ? "\(eventType.displayName)（\(amount)ml）"
            : eventType.displayName
        logLines.append("> \(actionLabel) の こうげき！")

        if isCritical {
            logLines.append("> 会心の一撃！ \(enemy.template.name) に \(playerDamage) の 大ダメージ！")
        } else if isResisted {
            logLines.append("> \(enemy.template.name) の 防壁に阻まれた！ \(playerDamage) ダメージ！")
        } else if isWeakness {
            logLines.append("> 弱点を突いた！ \(enemy.template.name) に \(playerDamage) ダメージ！")
        } else {
            logLines.append("> \(enemy.template.name) に \(playerDamage) ダメージ！")
        }

        // Apply player damage; heal types also restore party HP
        if attackType == .heal {
            let healAmount = max(0, playerDamage / 2)
            partyHP = min(BattleState.initialPartyHP, partyHP + healAmount)
            enemy.currentHP = max(0, enemy.currentHP - max(1, playerDamage / 2))
        } else {
            enemy.currentHP = max(0, enemy.currentHP - playerDamage)
        }

        // --- Enemy counter-attack or defeat ---
        let enemyDefeated = enemy.isDead
        var counterDamage = 0

        if enemyDefeated {
            killStreak += 1
            logLines.append("> \(enemy.template.name) を 撃破！")
            logLines.append("> ★ 連続討伐 \(killStreak) ★")
            let nextTemplate = EnemyRoster.randomTemplate(
                from: availableEnemies,
                excluding: enemy.template.name,
                randomSource: randomSource
            )
            enemy = Enemy(template: nextTemplate)
            logLines.append("> 新たな敵が現れた！")
            logLines.append("> [\(enemy.template.name) HP:\(enemy.template.maxHP)]")
        } else {
            counterDamage = computeCounterDamage(enemy: enemy, randomSource: randomSource)
            partyHP = max(0, partyHP - counterDamage)
            logLines.append("> \(enemy.template.name) が 反撃した！ パーティに \(counterDamage) ダメージ！")

            if partyHP <= 0 {
                partyHP = 30
                logLines.append("> ピンチ！ しかし おやは あきらめない！")
            }
        }

        let result = AttackResult(
            playerDamage: playerDamage,
            enemyCounterDamage: counterDamage,
            isResisted: isResisted,
            isWeakness: isWeakness,
            isCritical: isCritical,
            enemyDefeated: enemyDefeated,
            logLines: logLines
        )

        let newState = BattleState(
            enemy: enemy,
            partyHP: partyHP,
            killStreak: killStreak,
            battleLog: Array((state.battleLog + logLines).suffix(BattleState.logCap))
        )

        return (newState, result)
    }

    // MARK: - Private helpers (internal visibility for testing)

    // No accuracy roll — every attack always connects.
    // Crit (2x) ignores resist/weakness; resist = 0.5x; weakness = 1.8x.
    static func computePlayerDamage(
        member: PartyMember,
        isResisted: Bool,
        isWeakness: Bool,
        isCritical: Bool,
        randomSource: RandomSource
    ) -> Int {
        let spread = max(1, member.baseDamage / 4)
        let base = member.baseDamage - spread / 2 + randomSource.nextInt(spread)

        if isCritical {
            return max(1, base * 2)
        } else if isResisted {
            return max(1, base / 2)
        } else if isWeakness {
            return max(1, Int(Double(base) * 1.8))
        } else {
            return max(1, base)
        }
    }

    static func computeCounterDamage(enemy: Enemy, randomSource: RandomSource) -> Int {
        let base = max(1, enemy.template.attackPower / 2)  // halved from original
        let spread = max(1, base / 3)
        return max(1, base - spread / 2 + randomSource.nextInt(spread))
    }
}
