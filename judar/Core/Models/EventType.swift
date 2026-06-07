import Foundation

enum EventType: String, CaseIterable, Codable, Sendable {
    case poop       = "poop"
    case pee        = "pee"
    case breastfeed = "breastfeed"
    case formula    = "formula"

    var displayName: String {
        switch self {
        case .poop:       return "うんち"
        case .pee:        return "しっこ"
        case .breastfeed: return "母乳"
        case .formula:    return "ミルク"
        }
    }

    var icon: String {
        switch self {
        case .poop:       return "💩"
        case .pee:        return "💧"
        case .breastfeed: return "🤱"
        case .formula:    return "🍼"
        }
    }

    var attackType: AttackType {
        switch self {
        case .poop:       return .physical
        case .pee:        return .magical
        case .breastfeed: return .heal
        case .formula:    return .heal
        }
    }
}

enum AttackType: String, Codable, Sendable, Hashable {
    case physical
    case magical
    case heal
}
