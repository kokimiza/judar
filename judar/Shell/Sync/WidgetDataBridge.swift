import Foundation
import WidgetKit

struct WidgetDataBridge {
    static let appGroupID = "group.productions.jocarium.judar"
    static let countsKey  = "dailyCounts"

    static func write(counts: DailyCounts) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        if let data = try? JSONEncoder().encode(counts) {
            defaults.set(data, forKey: countsKey)
        }
    }

    static func read() -> DailyCounts {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: countsKey),
            let counts = try? JSONDecoder().decode(DailyCounts.self, from: data)
        else { return DailyCounts() }
        return counts
    }

    // Call from app side after every event log so the widget refreshes immediately
    static func requestWidgetTimelineReload() {
        WidgetCenter.shared.reloadTimelines(ofKind: "JudarWidget")
    }
}
