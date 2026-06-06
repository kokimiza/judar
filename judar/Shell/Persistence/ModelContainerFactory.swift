import Foundation
import SwiftData

enum ModelContainerFactory {

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([BabyEventRecord.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    // For unit tests: no disk persistence, no CloudKit
    static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([BabyEventRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
