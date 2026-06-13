import Foundation

struct DailyCounts: Sendable {
    var diaper: Int = 0
    var breastfeed: Int = 0
    var formula: Int = 0
    var pumpedMilk: Int = 0

    var total: Int { diaper + breastfeed + formula + pumpedMilk }

    subscript(eventType: EventType) -> Int {
        get {
            switch eventType {
            case .diaper: return diaper
            case .breastfeed: return breastfeed
            case .formula: return formula
            case .pumpedMilk: return pumpedMilk
            }
        }
        set {
            switch eventType {
            case .diaper: diaper = newValue
            case .breastfeed: breastfeed = newValue
            case .formula: formula = newValue
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
        lhs.diaper == rhs.diaper && lhs.breastfeed == rhs.breastfeed
            && lhs.formula == rhs.formula && lhs.pumpedMilk == rhs.pumpedMilk
    }
}

extension DailyCounts: Codable {
    private enum CodingKeys: String, CodingKey {
        case diaper, breastfeed, formula, pumpedMilk
    }
    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        diaper = (try? c.decode(Int.self, forKey: .diaper)) ?? 0
        breastfeed = try c.decode(Int.self, forKey: .breastfeed)
        formula = try c.decode(Int.self, forKey: .formula)
        pumpedMilk = (try? c.decode(Int.self, forKey: .pumpedMilk)) ?? 0
    }
    nonisolated func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(diaper, forKey: .diaper)
        try c.encode(breastfeed, forKey: .breastfeed)
        try c.encode(formula, forKey: .formula)
        try c.encode(pumpedMilk, forKey: .pumpedMilk)
    }
}
