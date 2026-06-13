import Foundation

// MARK: - Party

struct PartyMember: Sendable {
    let eventType: EventType
    let role: String
    let baseDamage: Int
    let accuracy: Double  // 0.0–1.0

    static let all: [PartyMember] = [
        PartyMember(
            eventType: .diaper,
            role: "武闘家",
            baseDamage: 14,
            accuracy: 0.80
        ),
        PartyMember(
            eventType: .breastfeed,
            role: "僧侶",
            baseDamage: 7,
            accuracy: 0.95
        ),
        PartyMember(
            eventType: .formula,
            role: "白魔道士",
            baseDamage: 5,
            accuracy: 0.95
        ),
        PartyMember(
            eventType: .pumpedMilk,
            role: "バード",
            baseDamage: 6,
            accuracy: 0.95
        ),
    ]

    static func member(for eventType: EventType) -> PartyMember {
        all.first { $0.eventType == eventType }!  // exhaustive enum — safe
    }
}

extension PartyMember: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.eventType == rhs.eventType
    }
}

// EventType knows its party member via extension (avoids circular file dependency)
extension EventType {
    var partyMember: PartyMember { PartyMember.member(for: self) }
}

// MARK: - Enemy

struct EnemyTemplate: Sendable {
    let name: String
    let maxHP: Int
    let resistances: Set<AttackType>
    let weaknesses: Set<AttackType>
    let attackPower: Int
    let asciiArt: String  // 3-line text art shown under enemy name
}

extension EnemyTemplate: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name && lhs.maxHP == rhs.maxHP
            && lhs.resistances == rhs.resistances
            && lhs.weaknesses == rhs.weaknesses
            && lhs.attackPower == rhs.attackPower
            && lhs.asciiArt == rhs.asciiArt
    }
}

struct Enemy: Sendable {
    let template: EnemyTemplate
    var currentHP: Int

    init(template: EnemyTemplate) {
        self.template = template
        self.currentHP = template.maxHP
    }

    var isDead: Bool { currentHP <= 0 }
    var hpFraction: Double {
        Double(max(0, currentHP)) / Double(template.maxHP)
    }
}

extension Enemy: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.template == rhs.template && lhs.currentHP == rhs.currentHP
    }
}

// MARK: - Battle

struct BattleState: Sendable {
    var enemy: Enemy
    var partyHP: Int
    var killStreak: Int
    var battleLog: [String]  // newest at tail, capped at 20 entries

    static let initialPartyHP = 100
    static let logCap = 20
}

extension BattleState: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.enemy == rhs.enemy && lhs.partyHP == rhs.partyHP
            && lhs.killStreak == rhs.killStreak
            && lhs.battleLog == rhs.battleLog
    }
}

struct AttackResult: Sendable {
    let playerDamage: Int
    let enemyCounterDamage: Int
    let isResisted: Bool
    let isWeakness: Bool
    let isCritical: Bool
    let enemyDefeated: Bool
    let logLines: [String]
}

extension AttackResult: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.playerDamage == rhs.playerDamage
            && lhs.enemyCounterDamage == rhs.enemyCounterDamage
            && lhs.isResisted == rhs.isResisted
            && lhs.isWeakness == rhs.isWeakness
            && lhs.isCritical == rhs.isCritical
            && lhs.enemyDefeated == rhs.enemyDefeated
            && lhs.logLines == rhs.logLines
    }
}

// MARK: - Event Record (pure value; Shell converts @Model -> this)

struct EventRecord: Sendable {
    let eventType: EventType
    let timestamp: Date
}

extension EventRecord: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.eventType == rhs.eventType && lhs.timestamp == rhs.timestamp
    }
}
