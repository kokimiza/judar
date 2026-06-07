import Foundation
import SwiftData
import CloudKit

@Observable
@MainActor
final class ProfileViewModel {
    private(set) var profile: LocalUserProfile?
    var isLoading       = false
    var isJoiningFamily = false
    var joinError: Error?

    private let modelContext: ModelContext
    let cloudKit: CloudKitSyncService

    init(modelContext: ModelContext, cloudKit: CloudKitSyncService) {
        self.modelContext = modelContext
        self.cloudKit     = cloudKit
    }

    // MARK: - Computed state

    var userId:    String { profile?.userId    ?? "" }
    var familyId:  String { profile?.familyId  ?? "" }
    var shareCode: String { profile?.shareCode ?? "" }
    var username:  String { profile?.username  ?? "" }

    var isProfileComplete: Bool {
        guard let profile else { return false }
        return !profile.username.trimmingCharacters(in: .whitespaces).isEmpty
            && profile.childBirthday != nil
    }

    // Enemy level based on child's days of life. Lv.1 on birth day, Lv.365 at 1 year.
    var enemyLevel: Int {
        guard let birthday = profile?.childBirthday else { return 1 }
        let cal  = Calendar.current
        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: birthday),
            to:   cal.startOfDay(for: Date())
        ).day ?? 0
        return max(1, days)
    }

    // MARK: - Lifecycle

    func loadOrCreate() async {
        guard profile == nil else { return }
        isLoading = true
        defer { isLoading = false }

        let descriptor = FetchDescriptor<LocalUserProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            profile = existing
        } else {
            await createProfile()
        }
    }

    // MARK: - Profile update

    func updateProfile(username: String, birthday: Date, gender: ChildGender) {
        guard let profile else { return }
        profile.username      = username.trimmingCharacters(in: .whitespaces)
        profile.childBirthday = birthday
        profile.childGender   = gender
    }

    // MARK: - Family sharing

    func joinFamily(ownerUserId: String, ownerShareCode: String) async throws {
        guard cloudKit.isAvailable else { throw JudarError.cloudKitUnavailable }
        isJoiningFamily = true
        defer { isJoiningFamily = false }

        let newFamilyId = try await cloudKit.joinFamily(
            ownerUserId: ownerUserId,
            shareCode: ownerShareCode.uppercased()
        )
        guard let profile else { return }
        profile.familyId = newFamilyId

        if !profile.cloudKitRecordName.isEmpty {
            try? await cloudKit.updateProfileFamilyId(userId: profile.userId, newFamilyId: newFamilyId)
        }
    }

    // MARK: - Private

    private func createProfile() async {
        let userId    = UUID().uuidString
        let familyId  = UUID().uuidString
        let shareCode = Self.generateShareCode()

        let local = LocalUserProfile()
        local.userId    = userId
        local.familyId  = familyId
        local.shareCode = shareCode
        modelContext.insert(local)
        profile = local

        guard cloudKit.isAvailable else { return }
        do {
            let record = try await cloudKit.createProfile(
                userId: userId, familyId: familyId, shareCode: shareCode, displayName: ""
            )
            local.cloudKitRecordName = record.recordID.recordName
        } catch {}
    }

    static func generateShareCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).compactMap { _ in chars.randomElement() })
    }
}
