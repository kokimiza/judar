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

    var memberName: String {
        switch self {
        case .poop:       return "ブリ丸"
        case .pee:        return "オシ魔神"
        case .breastfeed: return "ミルフ"
        case .formula:    return "粉白"
        }
    }
}

// Mirrors WidgetDataBridge.Payload in the main app — same Codable keys.
struct WDailyCounts: Codable {
    var poop: Int             = 0
    var pee: Int              = 0
    var breastfeed: Int       = 0
    var formula: Int          = 0
    var lastActionDate: Date? = nil

    subscript(et: WEventType) -> Int {
        switch et {
        case .poop:       return poop
        case .pee:        return pee
        case .breastfeed: return breastfeed
        case .formula:    return formula
        }
    }
}

func readWidgetData() -> WDailyCounts {
    guard
        let defaults = UserDefaults(suiteName: "group.productions.jocarium.judar"),
        let data     = defaults.data(forKey: "widgetPayload"),
        let payload  = try? JSONDecoder().decode(WDailyCounts.self, from: data)
    else { return WDailyCounts() }
    return payload
}

// MARK: - Timeline

struct JudarWidgetEntry: TimelineEntry {
    let date: Date
    let counts: WDailyCounts
}

struct JudarWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> JudarWidgetEntry {
        let sample = WDailyCounts(poop: 3, pee: 5, breastfeed: 2, formula: 1, lastActionDate: .now)
        return JudarWidgetEntry(date: .now, counts: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (JudarWidgetEntry) -> Void) {
        let data = context.isPreview ? placeholder(in: context).counts : readWidgetData()
        completion(JudarWidgetEntry(date: .now, counts: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JudarWidgetEntry>) -> Void) {
        let entry = JudarWidgetEntry(date: .now, counts: readWidgetData())
        // Refresh at midnight so daily counts reset automatically
        let midnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Calendar.current.date(byAdding: .hour, value: 6, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(midnight)))
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
        .description("今日の育児記録")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
