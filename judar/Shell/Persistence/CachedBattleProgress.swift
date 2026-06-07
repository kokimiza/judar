import Foundation
import SwiftData

@Model
final class CachedBattleProgress {
    var enemyName: String = ""
    var enemyCurrentHP: Int = 0
    var killStreak: Int = 0
    var partyHP: Int = 100
    var updatedAt: Date = Date()
    init() {}
}
