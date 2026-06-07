import CloudKit
import OSLog
import SwiftData
import SwiftUI
import WidgetKit

private let wlog = Logger(
    subsystem: "productions.jocarium.judar.widget",
    category: "DataPipeline"
)

// MARK: - Inline types (widget cannot import the main app module)

enum WEventType: String, CaseIterable {
    case poop = "poop"
    case pee = "pee"
    case breastfeed = "breastfeed"
    case formula = "formula"
    case pumpedMilk = "pumpedMilk"

    var displayName: String {
        switch self {
        case .poop: return "うんち"
        case .pee: return "しっこ"
        case .breastfeed: return "母乳"
        case .formula: return "ミルク"
        case .pumpedMilk: return "搾母乳"
        }
    }

    var icon: String {
        switch self {
        case .poop: return "💩"
        case .pee: return "💧"
        case .breastfeed: return "🤱"
        case .formula: return "🍼"
        case .pumpedMilk: return "🫙"
        }
    }
}

struct WDailyCounts: Codable {
    var poop: Int = 0
    var pee: Int = 0
    var breastfeed: Int = 0
    var formula: Int = 0
    var pumpedMilk: Int = 0
    var lastActionDate: Date? = nil
    var lastPoopDate: Date? = nil
    var lastPeeDate: Date? = nil
    var lastBreastfeedDate: Date? = nil
    var lastFormulaDate: Date? = nil
    var lastPumpedMilkDate: Date? = nil

    subscript(et: WEventType) -> Int {
        switch et {
        case .poop: return poop
        case .pee: return pee
        case .breastfeed: return breastfeed
        case .formula: return formula
        case .pumpedMilk: return pumpedMilk
        }
    }

    subscript(lastDate et: WEventType) -> Date? {
        switch et {
        case .poop: return lastPoopDate
        case .pee: return lastPeeDate
        case .breastfeed: return lastBreastfeedDate
        case .formula: return lastFormulaDate
        case .pumpedMilk: return lastPumpedMilkDate
        }
    }
}

// MARK: - SwiftData schema mirrors
// Property names and types must exactly match the main app for store compatibility.

@Model final class BabyEventRecord {
    var id: UUID = UUID()
    var eventTypeRaw: String = ""
    var timestamp: Date = Date()
    var familyId: String = ""
    var cloudKitRecordName: String = ""
    var isSynced: Bool = false
    var syncErrorRaw: String = ""
    var amount: Int = 0
    init() {}
}

@Model final class CachedEnemyRecord {
    var id: UUID = UUID()
    var cloudKitRecordName: String = ""
    var name: String = ""
    var maxHP: Int = 10
    var resistancesJSON: String = "[]"
    var weaknessesJSON: String = "[]"
    var attackPower: Int = 5
    var asciiArt: String = ""
    var lastSynced: Date = Date()
    init() {}
}

@Model final class LocalUserProfile {
    var userId: String = ""
    var appleUserId: String = ""
    var familyId: String = ""
    var shareCode: String = ""
    var username: String = ""
    var childBirthday: Date? = nil
    var childGenderRaw: String = ""
    var displayName: String = ""
    var cloudKitRecordName: String = ""
    var createdAt: Date = Date()
    init() {}
}

@Model final class CachedBattleProgress {
    var enemyName: String = ""
    var enemyCurrentHP: Int = 0
    var killStreak: Int = 0
    var partyHP: Int = 100
    var updatedAt: Date = Date()
    init() {}
}

// MARK: - Constants

private let kAppGroupID = "group.productions.jocarium.judar"
private let kStoreName = "judar.store"
private let kCKContainerID = "iCloud.productions.jocarium.judar"
private let kCKRecordType = "FamilyEvent"
private let kRefreshMinutes = 30

// MARK: - Data pipeline

/// Entry point: CloudKit → SwiftData fallback.
private func buildCounts() async -> WDailyCounts {
    wlog.debug("▶ buildCounts start")
    let familyId = await MainActor.run { localFamilyId() }
    wlog.debug("  familyId=\(familyId ?? "<nil>", privacy: .public)")

    if let fid = familyId, !fid.isEmpty {
        let ckResult = await cloudKitCounts(familyId: fid)
        if let counts = ckResult {
            wlog.debug(
                "  ✅ using CloudKit counts: poop=\(counts.poop) pee=\(counts.pee) breastfeed=\(counts.breastfeed) formula=\(counts.formula) pumpedMilk=\(counts.pumpedMilk)"
            )
            return counts
        }
        wlog.debug(
            "  ⚠️ cloudKitCounts returned nil → falling back to SwiftData"
        )
    } else {
        wlog.debug(
            "  ⚠️ familyId nil/empty → skipping CloudKit, using SwiftData"
        )
    }

    let local = await MainActor.run { localSwiftDataCounts() }
    wlog.debug(
        "  SwiftData counts: poop=\(local.poop) pee=\(local.pee) breastfeed=\(local.breastfeed) formula=\(local.formula)"
    )
    return local
}

/// Read familyId from the shared SwiftData store.
@MainActor
private func localFamilyId() -> String? {
    guard
        let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: kAppGroupID
        )
    else {
        wlog.error(
            "  ❌ App Group URL not found for \(kAppGroupID, privacy: .public)"
        )
        return nil
    }
    let storeFile = groupURL.appendingPathComponent(kStoreName)
    let exists = FileManager.default.fileExists(atPath: storeFile.path)
    wlog.debug(
        "  storeFile=\(storeFile.path, privacy: .public) exists=\(exists)"
    )
    guard let ctx = openLocalContext() else {
        wlog.error("  ❌ openLocalContext() returned nil")
        return nil
    }
    do {
        let profiles = try ctx.fetch(FetchDescriptor<LocalUserProfile>())
        wlog.debug("  LocalUserProfile count=\(profiles.count)")
        profiles.forEach { p in
            wlog.debug(
                "    profile userId=\(p.userId, privacy: .public) familyId=\(p.familyId, privacy: .public)"
            )
        }
        return profiles.first?.familyId
    } catch {
        wlog.error(
            "  ❌ fetch LocalUserProfile error: \(error, privacy: .public)"
        )
        return nil
    }
}

/// Fetch today's family events directly from CloudKit public DB.
private func cloudKitCounts(familyId: String) async -> WDailyCounts? {
    let cal = Calendar.current
    let todayStart = cal.startOfDay(for: .now)
    let recentStart = cal.date(byAdding: .day, value: -1, to: todayStart)!

    wlog.debug(
        "  CK query: familyId=\(familyId, privacy: .public) todayStart=\(todayStart) recentStart=\(recentStart)"
    )

    let pred = NSPredicate(
        format: "familyId == %@ AND timestamp >= %@",
        familyId,
        recentStart as CVarArg
    )
    let query = CKQuery(recordType: kCKRecordType, predicate: pred)
    query.sortDescriptors = [
        NSSortDescriptor(key: "timestamp", ascending: false)
    ]

    let db = CKContainer(identifier: kCKContainerID).publicCloudDatabase
    let result:
        (
            matchResults: [(CKRecord.ID, Result<CKRecord, Error>)],
            queryCursor: CKQueryOperation.Cursor?
        )
    do {
        result = try await db.records(matching: query, resultsLimit: 300)
    } catch {
        wlog.error("  ❌ CK query failed: \(error, privacy: .public)")
        return nil
    }

    var fetchErrors = 0
    let records = result.matchResults.compactMap { id, res -> CKRecord? in
        switch res {
        case .success(let r): return r
        case .failure(let e):
            fetchErrors += 1
            wlog.error(
                "    ❌ record \(id.recordName, privacy: .public) error: \(e, privacy: .public)"
            )
            return nil
        }
    }
    wlog.debug(
        "  CK matchResults=\(result.matchResults.count) decoded=\(records.count) errors=\(fetchErrors)"
    )

    var counts = WDailyCounts()
    var lastDates = [String: Date]()
    var skippedFieldMissing = 0

    for r in records {
        guard let typeRaw = r["eventTypeRaw"] as? String,
            let ts = r["timestamp"] as? Date
        else {
            skippedFieldMissing += 1
            wlog.debug(
                "    ⚠️ skipped record \(r.recordID.recordName, privacy: .public): eventTypeRaw=\(String(describing: r["eventTypeRaw"]), privacy: .public) timestamp=\(String(describing: r["timestamp"]), privacy: .public)"
            )
            continue
        }

        if lastDates[typeRaw] == nil { lastDates[typeRaw] = ts }

        guard ts >= todayStart else { continue }
        switch typeRaw {
        case "poop":       counts.poop += 1
        case "pee":        counts.pee += 1
        case "breastfeed": counts.breastfeed += 1
        case "formula":    counts.formula += 1
        case "pumpedMilk": counts.pumpedMilk += 1
        default:
            wlog.debug(
                "    ⚠️ unknown eventTypeRaw=\(typeRaw, privacy: .public)"
            )
        }
    }

    if skippedFieldMissing > 0 {
        wlog.warning(
            "  ⚠️ \(skippedFieldMissing) records skipped due to missing fields"
        )
    }
    wlog.debug(
        "  CK result: poop=\(counts.poop) pee=\(counts.pee) breastfeed=\(counts.breastfeed) formula=\(counts.formula) pumpedMilk=\(counts.pumpedMilk)"
    )

    counts.lastActionDate = lastDates.values.max()
    counts.lastPoopDate = lastDates["poop"]
    counts.lastPeeDate = lastDates["pee"]
    counts.lastBreastfeedDate = lastDates["breastfeed"]
    counts.lastFormulaDate = lastDates["formula"]
    counts.lastPumpedMilkDate = lastDates["pumpedMilk"]
    return counts
}

/// Fallback: read today's counts from the local SwiftData store.
@MainActor
private func localSwiftDataCounts() -> WDailyCounts {
    guard let ctx = openLocalContext() else {
        wlog.error("  ❌ localSwiftDataCounts: openLocalContext() nil")
        return WDailyCounts()
    }
    let all: [BabyEventRecord]
    do {
        all = try ctx.fetch(FetchDescriptor<BabyEventRecord>())
    } catch {
        wlog.error(
            "  ❌ fetch BabyEventRecord error: \(error, privacy: .public)"
        )
        return WDailyCounts()
    }
    wlog.debug("  SwiftData total BabyEventRecords=\(all.count)")

    let cal = Calendar.current
    let todayStart = cal.startOfDay(for: .now)
    let recentStart = cal.date(byAdding: .day, value: -1, to: todayStart)!

    var counts = WDailyCounts()
    var lastDates = [String: Date]()
    var todayCount = 0

    for r in all.sorted(by: { $0.timestamp > $1.timestamp }) {
        if r.timestamp >= recentStart, lastDates[r.eventTypeRaw] == nil {
            lastDates[r.eventTypeRaw] = r.timestamp
        }
        guard r.timestamp >= todayStart else { continue }
        todayCount += 1
        switch r.eventTypeRaw {
        case "poop":       counts.poop += 1
        case "pee":        counts.pee += 1
        case "breastfeed": counts.breastfeed += 1
        case "formula":    counts.formula += 1
        case "pumpedMilk": counts.pumpedMilk += 1
        default:
            wlog.debug(
                "    ⚠️ SwiftData unknown eventTypeRaw=\(r.eventTypeRaw, privacy: .public)"
            )
        }
    }
    wlog.debug("  SwiftData todayRecords=\(todayCount)")

    counts.lastActionDate = lastDates.values.max()
    counts.lastPoopDate = lastDates["poop"]
    counts.lastPeeDate = lastDates["pee"]
    counts.lastBreastfeedDate = lastDates["breastfeed"]
    counts.lastFormulaDate = lastDates["formula"]
    counts.lastPumpedMilkDate = lastDates["pumpedMilk"]
    return counts
}

/// Open the shared SQLite store. Returns nil if store file doesn't exist yet.
@MainActor
private func openLocalContext() -> ModelContext? {
    guard
        let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: kAppGroupID
        )
    else {
        wlog.error(
            "  ❌ containerURL nil for appGroup=\(kAppGroupID, privacy: .public)"
        )
        return nil
    }
    let storeURL = groupURL.appendingPathComponent(kStoreName)
    guard FileManager.default.fileExists(atPath: storeURL.path) else {
        wlog.warning(
            "  ⚠️ store not found at \(storeURL.path, privacy: .public)"
        )
        return nil
    }
    let schema = Schema([
        BabyEventRecord.self, CachedEnemyRecord.self, LocalUserProfile.self,
        CachedBattleProgress.self,
    ])
    let config = ModelConfiguration(schema: schema, url: storeURL)
    do {
        let container = try ModelContainer(
            for: schema,
            configurations: [config]
        )
        return ModelContext(container)
    } catch {
        wlog.error("  ❌ ModelContainer init error: \(error, privacy: .public)")
        return nil
    }
}

// MARK: - Timeline

struct JudarWidgetEntry: TimelineEntry {
    let date: Date
    let counts: WDailyCounts
}

struct JudarWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> JudarWidgetEntry {
        let sample = WDailyCounts(
            poop: 3,
            pee: 5,
            breastfeed: 2,
            formula: 1,
            lastActionDate: .now
        )
        return JudarWidgetEntry(date: .now, counts: sample)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (JudarWidgetEntry) -> Void
    ) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            completion(
                JudarWidgetEntry(date: .now, counts: await buildCounts())
            )
        }
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<JudarWidgetEntry>) -> Void
    ) {
        Task {
            let counts = await buildCounts()
            let entry = JudarWidgetEntry(date: .now, counts: counts)
            let nextFetch = Calendar.current.date(
                byAdding: .minute,
                value: kRefreshMinutes,
                to: .now
            )!
            completion(Timeline(entries: [entry], policy: .after(nextFetch)))
        }
    }
}

// MARK: - Widget

struct JudarWidget: Widget {
    let kind = "JudarWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JudarWidgetProvider()) {
            entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("judar")
        .description("今日の育児記録")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
