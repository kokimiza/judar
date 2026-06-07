import Foundation
import SwiftData

// Local cache of CloudKit EnemyMaster records.
// Pure conversion back to Core EnemyTemplate via toTemplate().
@Model
final class CachedEnemyRecord {
    var id: UUID = UUID()
    var cloudKitRecordName: String = ""
    var name: String = ""
    var maxHP: Int = 10
    var resistancesJSON: String = "[]"  // JSON array of AttackType rawValues
    var weaknessesJSON: String = "[]"
    var attackPower: Int = 5
    var asciiArt: String = ""
    var lastSynced: Date = Date()

    init() {}

    func toTemplate() -> EnemyTemplate? {
        guard
            let rData = resistancesJSON.data(using: .utf8),
            let wData = weaknessesJSON.data(using: .utf8),
            let rStrings = try? JSONDecoder().decode(
                [String].self,
                from: rData
            ),
            let wStrings = try? JSONDecoder().decode(
                [String].self,
                from: wData
            ),
            !name.isEmpty, maxHP > 0
        else { return nil }

        return EnemyTemplate(
            name: name,
            maxHP: maxHP,
            resistances: Set(rStrings.compactMap(AttackType.init)),
            weaknesses: Set(wStrings.compactMap(AttackType.init)),
            attackPower: attackPower,
            asciiArt: asciiArt
        )
    }
}
