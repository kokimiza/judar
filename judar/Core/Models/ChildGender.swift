import Foundation

enum ChildGender: String, CaseIterable, Codable, Sendable {
    case male   = "male"
    case female = "female"

    var displayName: String {
        switch self {
        case .male:   return "男の子"
        case .female: return "女の子"
        }
    }
}
