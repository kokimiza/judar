import CloudKit
import Foundation
import SwiftData

@Observable
@MainActor
final class ProfileViewModel {
    private(set) var profile: LocalUserProfile?
    var isLoading = false
    var isJoiningFamily = false
    var joinError: Error?

    private let modelContext: ModelContext
    private let cloudKit: CloudKitSyncService

    var isCloudKitAvailable: Bool { cloudKit.isAvailable }

    init(modelContext: ModelContext, cloudKit: CloudKitSyncService) {
        self.modelContext = modelContext
        self.cloudKit = cloudKit
    }

    // MARK: - Computed state

    var userId: String { profile?.userId ?? "" }
    var familyId: String { profile?.familyId ?? "" }
    var shareCode: String { profile?.shareCode ?? "" }

    var isProfileComplete: Bool { profile != nil }

    // MARK: - CloudKit verification (Apple-signed users only)

    enum CloudKitVerifyResult {
        case found
        case notFound
        case unavailable
    }

    func loadLocalOnly() async {
        guard profile == nil else { return }
        profile = try? modelContext.fetch(FetchDescriptor<LocalUserProfile>())
            .first
    }

    func verifyWithCloudKit() async -> CloudKitVerifyResult {
        await cloudKit.checkAccountStatus()
        guard cloudKit.isAvailable else { return .unavailable }
        guard let local = profile, !local.userId.isEmpty else {
            return .notFound
        }
        do {
            return try await cloudKit.fetchProfile(userId: local.userId) != nil
                ? .found : .notFound
        } catch {
            return .unavailable
        }
    }

    func clearLocalProfile() {
        guard let p = profile else { return }
        modelContext.delete(p)
        profile = nil
    }

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

    // MARK: - Guest → Apple ID upgrade

    func upgradeFromGuest() async {
        cloudKit.setGuestMode(false)
        await cloudKit.checkAccountStatus()
        guard cloudKit.isAvailable, let profile,
            profile.cloudKitRecordName.isEmpty
        else { return }
        do {
            let record = try await cloudKit.createProfile(
                userId: profile.userId,
                familyId: profile.familyId,
                shareCode: profile.shareCode,
                displayName: ""
            )
            profile.cloudKitRecordName = record.recordID.recordName
        } catch {}
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
            try? await cloudKit.updateProfileFamilyId(
                userId: profile.userId,
                newFamilyId: newFamilyId
            )
        }
    }

    // MARK: - Private

    private func createProfile() async {
        let userId = UUID().uuidString
        let familyId = UUID().uuidString
        let shareCode = Self.generateShareCode()

        let local = LocalUserProfile()
        local.userId = userId
        local.familyId = familyId
        local.shareCode = shareCode
        modelContext.insert(local)
        profile = local

        guard cloudKit.isAvailable else { return }
        do {
            let record = try await cloudKit.createProfile(
                userId: userId,
                familyId: familyId,
                shareCode: shareCode,
                displayName: ""
            )
            local.cloudKitRecordName = record.recordID.recordName
        } catch {}
    }

    static func generateShareCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).compactMap { _ in chars.randomElement() })
    }
}
