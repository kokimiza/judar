import Foundation
import SwiftData

enum ModelContainerFactory {

    // CloudKit sync is managed manually via CloudKitSyncService.
    // SwiftData is local SQLite only (no .automatic CloudKit integration).
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            BabyEventRecord.self,
            CachedEnemyRecord.self,
            LocalUserProfile.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Previous CloudKit-enabled schema may be incompatible — clear and restart
            let storeURL = URL.applicationSupportDirectory
                .appendingPathComponent("default.store")
            try? FileManager.default.removeItem(at: storeURL)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            BabyEventRecord.self,
            CachedEnemyRecord.self,
            LocalUserProfile.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
