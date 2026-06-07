import Foundation

enum EventType: String, CaseIterable, Codable, Sendable {
    case poop = "poop"
    case pee = "pee"
    case breastfeed = "breastfeed"
    case formula = "formula"
    case pumpedMilk = "pumpedMilk"

    var displayName: String {
        switch self {
        case .poop: return "うんち"
        case .pee: return "しっこ"
        case .breastfeed: return "母乳"
        case .formula: return "ミルク"
        case .pumpedMilk: return "搾母乳"
        }
    }

    var icon: String {
        switch self {
        case .poop: return "toilet.fill"
        case .pee: return "drop.fill"
        case .breastfeed: return "heart.fill"
        case .formula: return "waterbottle.fill"
        case .pumpedMilk: return "syringe.fill"
        }
    }

    var attackType: AttackType {
        switch self {
        case .poop: return .physical
        case .pee: return .magical
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
