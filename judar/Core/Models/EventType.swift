import Foundation

enum EventType: String, CaseIterable, Codable, Sendable {
    case diaper = "diaper"
    case breastfeed = "breastfeed"
    case formula = "formula"
    case pumpedMilk = "pumpedMilk"

    var displayName: String {
        switch self {
        case .diaper: return "オムツ交換"
        case .breastfeed: return "母乳"
        case .formula: return "ミルク"
        case .pumpedMilk: return "搾母乳"
        }
    }

    var icon: String {
        switch self {
        case .diaper: return "hands.sparkles.fill"
        case .breastfeed: return "heart.fill"
        case .formula: return "waterbottle.fill"
        case .pumpedMilk: return "syringe.fill"
        }
    }

    var attackType: AttackType {
        switch self {
        case .diaper: return .physical
        case .breastfeed: return .heal
        case .formula: return .heal
        case .pumpedMilk: return .heal
        }
    }
}

enum AttackType: String, Codable, Sendable, Hashable {
    case physical
    case magical
    case heal
}
