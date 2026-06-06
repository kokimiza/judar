import Foundation

struct DailyCounts: Codable, Equatable, Sendable {
    var poop: Int       = 0
    var pee: Int        = 0
    var breastfeed: Int = 0
    var formula: Int    = 0

    var total: Int { poop + pee + breastfeed + formula }

    subscript(eventType: EventType) -> Int {
        get {
            switch eventType {
            case .poop:       return poop
            case .pee:        return pee
            case .breastfeed: return breastfeed
            case .formula:    return formula
            }
        }
        set {
            switch eventType {
            case .poop:       poop = newValue
            case .pee:        pee = newValue
            case .breastfeed: breastfeed = newValue
            case .formula:    formula = newValue
            }
        }
    }
}
