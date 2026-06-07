import Foundation
import SwiftData

@Model
final class LocalUserProfile {
    // Identity
    var userId: String             = ""
    var appleUserId: String        = ""

    // Family sharing
    var familyId: String           = ""
    var shareCode: String          = ""

    // User-set profile
    var username: String           = ""
    var childBirthday: Date?       = nil
    var childGenderRaw: String     = ""   // ChildGender.rawValue

    // Metadata
    var displayName: String        = ""
    var cloudKitRecordName: String = ""
    var createdAt: Date            = Date()

    init() {}

    var childGender: ChildGender {
        get { ChildGender(rawValue: childGenderRaw) ?? .male }
        set { childGenderRaw = newValue.rawValue }
    }
}
