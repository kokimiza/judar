import Foundation
import WidgetKit

struct WidgetDataBridge {
    static let appGroupID = "group.productions.jocarium.judar"
    static let payloadKey = "widgetPayload"

    // Payload written by the app and read by the widget.
    // Fields mirror WDailyCounts in JudarWidget.swift (same Codable keys).
    struct Payload: Codable {
        var poop: Int           = 0
        var pee: Int            = 0
        var breastfeed: Int     = 0
        var formula: Int        = 0
        var lastActionDate: Date? = nil
    }

    static func write(counts: DailyCounts, lastActionDate: Date = .now) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let payload = Payload(
            poop: counts.poop,
            pee: counts.pee,
            breastfeed: counts.breastfeed,
            formula: counts.formula,
            lastActionDate: lastActionDate
        )
        if let data = try? JSONEncoder().encode(payload) {
            defaults.set(data, forKey: payloadKey)
        }
    }

    static func requestWidgetTimelineReload() {
        WidgetCenter.shared.reloadTimelines(ofKind: "JudarWidget")
    }
}
