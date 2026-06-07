import Foundation
import SwiftData

enum ModelContainerFactory {

    static let appGroupID = "group.productions.jocarium.judar"
    static let storeName = "judar.store"

    // Stored in the App Group container so the widget extension can read the same SQLite file.
    static var storeURL: URL {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(storeName)
            ?? URL.applicationSupportDirectory.appendingPathComponent(storeName)
    }

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            BabyEventRecord.self,
            CachedEnemyRecord.self,
            LocalUserProfile.self,
            CachedBattleProgress.self,
        ])
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            try? FileManager.default.removeItem(at: storeURL)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            BabyEventRecord.self,
            CachedEnemyRecord.self,
            LocalUserProfile.self,
            CachedBattleProgress.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
