import CloudKit
import Foundation

// MARK: - CloudKit record type / field constants

enum CKRType {
    static let enemyMaster = "EnemyMaster"
    static let userProfile = "UserProfile"
    static let familyEvent = "FamilyEvent"
    static let battleProgress = "BattleProgress"
}

enum BattleProgressF {
    static let enemyName = "enemyName"
    static let enemyCurrentHP = "enemyCurrentHP"
    static let killStreak = "killStreak"
    static let partyHP = "partyHP"
    static let familyId = "familyId"
    static let userId = "userId"
}

enum EnemyF {
    static let name = "name"
    static let maxHP = "maxHP"
    static let resistances = "resistances"
    static let weaknesses = "weaknesses"
    static let attackPower = "attackPower"
    static let asciiArt = "asciiArt"
}

enum UserF {
    static let userId = "userId"
    static let familyId = "familyId"
    static let shareCode = "shareCode"
    static let displayName = "displayName"
}

enum EventF {
    static let eventTypeRaw = "eventTypeRaw"
    static let timestamp = "timestamp"
    static let familyId = "familyId"
    static let userId = "userId"
}

// MARK: - Service

@Observable
final class CloudKitSyncService {
    // iCloud account is signed in and reachable
    private(set) var isAccountAvailable = false
    // Set once during boot; guest mode blocks all CloudKit operations
    private(set) var isGuestMode = false
    var lastError: Error?

    // Single guard for all callers — false in guest mode OR when iCloud is unavailable
    var isAvailable: Bool { isAccountAvailable && !isGuestMode }

    private let ckContainer: CKContainer
    private var publicDB: CKDatabase { ckContainer.publicCloudDatabase }

    init() {
        ckContainer = CKContainer(
            identifier: "iCloud.productions.jocarium.judar"
        )
        Task { await checkAccountStatus() }
    }

    func setGuestMode(_ guest: Bool) {
        isGuestMode = guest
    }

    func checkAccountStatus() async {
        do {
            let status = try await ckContainer.accountStatus()
            isAccountAvailable = (status == .available)
        } catch {
            isAccountAvailable = false
            lastError = error
        }
    }

    // MARK: - Enemy Master

    func fetchAllEnemies() async throws -> [CKRecord] {
        let query = CKQuery(
            recordType: CKRType.enemyMaster,
            predicate: NSPredicate(value: true)
        )
        let result = try await publicDB.records(
            matching: query,
            resultsLimit: 200
        )
        return result.matchResults.compactMap { try? $0.1.get() }
    }

    // Developer utility: seed hardcoded EnemyRoster into CloudKit if the table is empty.
    func seedEnemiesIfNeeded() async throws {
        let existing = try await fetchAllEnemies()
        guard existing.isEmpty else { return }

        for template in EnemyRoster.all {
            let record = CKRecord(recordType: CKRType.enemyMaster)
            record[EnemyF.name] = template.name
            record[EnemyF.maxHP] = template.maxHP as CKRecordValue
            record[EnemyF.attackPower] = template.attackPower as CKRecordValue
            record[EnemyF.asciiArt] = template.asciiArt
            record[EnemyF.resistances] =
                template.resistances.map(\.rawValue) as CKRecordValue
            record[EnemyF.weaknesses] =
                template.weaknesses.map(\.rawValue) as CKRecordValue
            _ = try await publicDB.save(record)
        }
    }

    // MARK: - User Profile

    func createProfile(
        userId: String,
        familyId: String,
        shareCode: String,
        displayName: String
    ) async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: userId)
        let record = CKRecord(
            recordType: CKRType.userProfile,
            recordID: recordID
        )
        record[UserF.userId] = userId
        record[UserF.familyId] = familyId
        record[UserF.shareCode] = shareCode
        record[UserF.displayName] = displayName
        return try await publicDB.save(record)
    }

    func fetchProfile(userId: String) async throws -> CKRecord? {
        let recordID = CKRecord.ID(recordName: userId)
        do {
            return try await publicDB.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
        // All other CKErrors propagate — verifyWithCloudKit maps them to .unavailable
    }

    // Verify shareCode → return the owner's familyId
    func joinFamily(ownerUserId: String, shareCode: String) async throws
        -> String
    {
        guard let ownerRecord = try await fetchProfile(userId: ownerUserId)
        else {
            throw JudarError.userNotFound
        }
        guard
            (ownerRecord[UserF.shareCode] as? String) == shareCode.uppercased()
        else {
            throw JudarError.invalidShareCode
        }
        guard let familyId = ownerRecord[UserF.familyId] as? String else {
            throw JudarError.userNotFound
        }
        return familyId
    }

    func updateProfileFamilyId(userId: String, newFamilyId: String) async throws
    {
        guard let record = try await fetchProfile(userId: userId) else {
            return
        }
        record[UserF.familyId] = newFamilyId
        _ = try await publicDB.save(record)
    }

    // MARK: - Family Events

    func pushEvent(
        eventTypeRaw: String,
        timestamp: Date,
        familyId: String,
        userId: String
    ) async throws -> CKRecord {
        let record = CKRecord(recordType: CKRType.familyEvent)
        record[EventF.eventTypeRaw] = eventTypeRaw
        record[EventF.timestamp] = timestamp as CKRecordValue
        record[EventF.familyId] = familyId
        record[EventF.userId] = userId
        return try await publicDB.save(record)
    }

    func fetchEvents(familyId: String, since: Date) async throws -> [CKRecord] {
        let pred = NSPredicate(
            format: "familyId == %@ AND timestamp >= %@",
            familyId,
            since as CVarArg
        )
        let query = CKQuery(recordType: CKRType.familyEvent, predicate: pred)
        query.sortDescriptors = [
            NSSortDescriptor(key: EventF.timestamp, ascending: false)
        ]
        let result = try await publicDB.records(
            matching: query,
            resultsLimit: 500
        )
        return result.matchResults.compactMap { try? $0.1.get() }
    }

    // Subscribe to new family events via silent push notification
    func subscribeFamilyEvents(familyId: String) async throws {
        let pred = NSPredicate(format: "familyId == %@", familyId)
        let sub = CKQuerySubscription(
            recordType: CKRType.familyEvent,
            predicate: pred,
            subscriptionID: "family-events-\(familyId)",
            options: .firesOnRecordCreation
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        sub.notificationInfo = info
        _ = try await publicDB.save(sub)
    }

    // MARK: - Battle Progress

    func saveBattleProgress(
        enemyName: String,
        enemyCurrentHP: Int,
        killStreak: Int,
        partyHP: Int,
        familyId: String,
        userId: String
    ) async throws {
        let recordID = CKRecord.ID(recordName: "battleProgress_\(familyId)")
        let record: CKRecord
        if let existing = try? await publicDB.record(for: recordID) {
            record = existing
        } else {
            record = CKRecord(
                recordType: CKRType.battleProgress,
                recordID: recordID
            )
        }
        record[BattleProgressF.enemyName] = enemyName
        record[BattleProgressF.enemyCurrentHP] = enemyCurrentHP as CKRecordValue
        record[BattleProgressF.killStreak] = killStreak as CKRecordValue
        record[BattleProgressF.partyHP] = partyHP as CKRecordValue
        record[BattleProgressF.familyId] = familyId
        record[BattleProgressF.userId] = userId
        _ = try await publicDB.save(record)
    }

    func fetchBattleProgress(familyId: String) async throws -> CKRecord? {
        let recordID = CKRecord.ID(recordName: "battleProgress_\(familyId)")
        return try? await publicDB.record(for: recordID)
    }

    // MARK: - Helpers

    func stringArray(from record: CKRecord, key: String) -> [String] {
        if let arr = record[key] as? [String] { return arr }
        if let ns = record[key] as? NSArray {
            return ns.compactMap { $0 as? String }
        }
        return []
    }
}
