import Foundation

// MARK: - Party

struct PartyMember: Equatable, Sendable {
    let eventType: EventType
    let name: String
    let role: String
    let baseDamage: Int
    let accuracy: Double  // 0.0–1.0

    static let all: [PartyMember] = [
        PartyMember(eventType: .poop,       name: "ブリ丸",   role: "戦士",     baseDamage: 15, accuracy: 0.75),
        PartyMember(eventType: .pee,        name: "オシ魔神", role: "魔法使い", baseDamage: 12, accuracy: 0.90),
        PartyMember(eventType: .breastfeed, name: "ミルフ",   role: "僧侶",     baseDamage: 7,  accuracy: 0.95),
        PartyMember(eventType: .formula,    name: "粉白",     role: "白魔道士", baseDamage: 5,  accuracy: 0.95),
    ]

    static func member(for eventType: EventType) -> PartyMember {
        all.first { $0.eventType == eventType }!  // exhaustive enum — safe
    }
}

// EventType knows its party member via extension (avoids circular file dependency)
extension EventType {
    var partyMember: PartyMember { PartyMember.member(for: self) }
}

// MARK: - Enemy

struct EnemyTemplate: Equatable, Sendable {
    let name: String
    let maxHP: Int
    let resistances: Set<AttackType>
    let weaknesses: Set<AttackType>
    let attackPower: Int
    let asciiArt: String  // 3-line text art shown under enemy name
}

struct Enemy: Equatable, Sendable {
    let template: EnemyTemplate
    var currentHP: Int

    init(template: EnemyTemplate) {
        self.template = template
        self.currentHP = template.maxHP
    }

    var isDead: Bool { currentHP <= 0 }
    var hpFraction: Double { Double(max(0, currentHP)) / Double(template.maxHP) }
}

// MARK: - Battle

struct BattleState: Equatable, Sendable {
    var enemy: Enemy
    var partyHP: Int
    var killStreak: Int
    var battleLog: [String]  // newest at tail, capped at 20 entries

    static let initialPartyHP = 100
    static let logCap = 20
}

struct AttackResult: Equatable, Sendable {
    let playerDamage: Int
    let enemyCounterDamage: Int
    let isResisted: Bool
    let isWeakness: Bool
    let enemyDefeated: Bool
    let logLines: [String]
}

// MARK: - Event Record (pure value; Shell converts @Model -> this)

struct EventRecord: Equatable, Sendable {
    let eventType: EventType
    let timestamp: Date
}
