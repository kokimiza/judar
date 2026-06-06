import WidgetKit
import SwiftUI

// MARK: - Inline types (widget target cannot import the main app module)

enum WEventType: String, CaseIterable {
    case poop       = "poop"
    case pee        = "pee"
    case breastfeed = "breastfeed"
    case formula    = "formula"

    var displayName: String {
        switch self {
        case .poop:       return "うんち"
        case .pee:        return "しっこ"
        case .breastfeed: return "母乳"
        case .formula:    return "ミルク"
        }
    }
}

struct WDailyCounts: Codable {
    var poop: Int       = 0
    var pee: Int        = 0
    var breastfeed: Int = 0
    var formula: Int    = 0

    subscript(et: WEventType) -> Int {
        switch et {
        case .poop:       return poop
        case .pee:        return pee
        case .breastfeed: return breastfeed
        case .formula:    return formula
        }
    }
}

func readWidgetCounts() -> WDailyCounts {
    guard
        let defaults = UserDefaults(suiteName: "group.productions.jocarium.judar"),
        let data     = defaults.data(forKey: "dailyCounts"),
        let counts   = try? JSONDecoder().decode(WDailyCounts.self, from: data)
    else { return WDailyCounts() }
    return counts
}

// MARK: - Timeline

struct JudarWidgetEntry: TimelineEntry {
    let date: Date
    let counts: WDailyCounts
}

struct JudarWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> JudarWidgetEntry {
        JudarWidgetEntry(date: .now, counts: WDailyCounts())
    }
    func getSnapshot(in context: Context, completion: @escaping (JudarWidgetEntry) -> Void) {
        completion(JudarWidgetEntry(date: .now, counts: readWidgetCounts()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<JudarWidgetEntry>) -> Void) {
        let entry = JudarWidgetEntry(date: .now, counts: readWidgetCounts())
        let next  = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget

struct JudarWidget: Widget {
    let kind = "JudarWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JudarWidgetProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("judar")
        .description("今日の記録")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
