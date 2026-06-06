import SwiftUI
import SwiftData

@main
struct judarApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainerFactory.makeContainer()
        } catch {
            fatalError("ModelContainer 作成失敗: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
