import Foundation
import SwiftData

@Model
final class LocalUserProfile {
    // Identity
    var userId: String = ""
    var appleUserId: String = ""

    // Family sharing
    var familyId: String = ""
    var shareCode: String = ""

    // Metadata
    var cloudKitRecordName: String = ""
    var createdAt: Date = Date()

    init() {}
}
