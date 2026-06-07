import Foundation

struct DailyCounts: Sendable {
    var poop: Int        = 0
    var pee: Int         = 0
    var breastfeed: Int  = 0
    var formula: Int     = 0
    var pumpedMilk: Int  = 0

    var total: Int { poop + pee + breastfeed + formula + pumpedMilk }

    subscript(eventType: EventType) -> Int {
        get {
            switch eventType {
            case .poop:       return poop
            case .pee:        return pee
            case .breastfeed: return breastfeed
            case .formula:    return formula
            case .pumpedMilk: return pumpedMilk
            }
        }
        set {
            switch eventType {
            case .poop:       poop       = newValue
            case .pee:        pee        = newValue
            case .breastfeed: breastfeed = newValue
            case .formula:    formula    = newValue
            case .pumpedMilk: pumpedMilk = newValue
            }
        }
    }
}

// nonisolated conformances — Core types must be callable from any actor context.
// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor would otherwise make synthesized
// implementations @MainActor, blocking use in nonisolated test/async code.

extension DailyCounts: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.poop == rhs.poop &&
        lhs.pee  == rhs.pee  &&
        lhs.breastfeed == rhs.breastfeed &&
        lhs.formula    == rhs.formula &&
        lhs.pumpedMilk == rhs.pumpedMilk
    }
}

extension DailyCounts: Codable {
    private enum CodingKeys: String, CodingKey {
        case poop, pee, breastfeed, formula, pumpedMilk
    }
    nonisolated init(from decoder: Decoder) throws {
        let c  = try decoder.container(keyedBy: CodingKeys.self)
        poop       = try c.decode(Int.self, forKey: .poop)
        pee        = try c.decode(Int.self, forKey: .pee)
        breastfeed = try c.decode(Int.self, forKey: .breastfeed)
        formula    = try c.decode(Int.self, forKey: .formula)
        pumpedMilk = (try? c.decode(Int.self, forKey: .pumpedMilk)) ?? 0
    }
    nonisolated func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(poop,       forKey: .poop)
        try c.encode(pee,        forKey: .pee)
        try c.encode(breastfeed, forKey: .breastfeed)
        try c.encode(formula,    forKey: .formula)
        try c.encode(pumpedMilk, forKey: .pumpedMilk)
    }
}
