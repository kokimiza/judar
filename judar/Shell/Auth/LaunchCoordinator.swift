import OSLog
import SwiftData
import SwiftUI

private let lclog = Logger(
    subsystem: "productions.jocarium.judar",
    category: "LaunchCoordinator"
)

// MARK: - App-level phase (Shell owns routing state)

enum AppPhase {
    case checking
    case signIn
    case home
}

// MARK: - LaunchCoordinator

@Observable
@MainActor
final class LaunchCoordinator {

    // MARK: Owned services

    private(set) var authSvc = AuthService()
    private var cloudKit = CloudKitSyncService()
    private(set) var themeManager = ThemeManager()

    // MARK: Published state (ContentView observes)

    private(set) var phase: AppPhase = .checking
    private(set) var profileVM: ProfileViewModel?
    private(set) var battleVM: BattleViewModel?

    // Launch-screen sub-states
    private(set) var launchMessage = "> 起動中..."
    private(set) var cloudKitVerifyFailed = false

    // MARK: Computed

    var canProceed: Bool { authSvc.canProceed }

    // MARK: - Entry points

    func start(modelContext: ModelContext) async {
        lclog.debug("▶ start isGuest=\(self.authSvc.isGuest)")
        if authSvc.isGuest {
            await bootServices(modelContext: modelContext)
            return
        }
        let valid = await authSvc.checkStoredAuth()
        lclog.debug("  checkStoredAuth valid=\(valid)")
        if valid {
            await bootServices(modelContext: modelContext)
        } else {
            phase = .signIn
        }
    }

    func bootServices(modelContext: ModelContext) async {
        cloudKit.setGuestMode(authSvc.isGuest)

        let pvm = ProfileViewModel(
            modelContext: modelContext,
            cloudKit: cloudKit
        )
        let bvm = BattleViewModel(
            modelContext: modelContext,
            cloudKit: cloudKit
        )
        profileVM = pvm
        battleVM = bvm

        if authSvc.isGuest {
            lclog.debug("  guest path — local only")
            launchMessage = "> プロフィール読み込み中..."
            await pvm.loadOrCreate()
            await seedEnemiesOnce()
            await bvm.restoreProgress(
                familyId: pvm.familyId,
                userId: pvm.userId
            )
            phase = .home
            return
        }

        // Apple-signed: CloudKit is the authoritative gate
        lclog.debug("  Apple-signed path — verifying with CloudKit")
        launchMessage = "> プロフィールを確認中..."
        await cloudKit.checkAccountStatus()
        await pvm.loadLocalOnly()
        await verifyAndRoute(pvm: pvm, bvm: bvm)
    }

    func retryCloudKitVerification(modelContext: ModelContext) async {
        cloudKitVerifyFailed = false
        launchMessage = "> 再接続中..."
        await start(modelContext: modelContext)
    }

    // MARK: - Private

    private func verifyAndRoute(pvm: ProfileViewModel, bvm: BattleViewModel)
        async
    {
        let result = await verifyWithCloudKitRetrying(pvm: pvm)
        switch result {
        case .found:
            lclog.debug("  CK verify: found")
            launchMessage = "> 起動中..."
            await seedEnemiesOnce()
            await bvm.restoreProgress(
                familyId: pvm.familyId,
                userId: pvm.userId
            )
            phase = .home

        case .notFound:
            lclog.warning("  CK verify: notFound — recreating profile")
            pvm.clearLocalProfile()
            await pvm.loadOrCreate()
            await seedEnemiesOnce()
            await bvm.restoreProgress(
                familyId: pvm.familyId,
                userId: pvm.userId
            )
            phase = .home

        case .unavailable:
            lclog.warning("  CK verify: unavailable — showing retry panel")
            cloudKitVerifyFailed = true
        }
    }

    private func verifyWithCloudKitRetrying(pvm: ProfileViewModel) async
        -> ProfileViewModel.CloudKitVerifyResult
    {
        let maxAttempts = 3
        for attempt in 1...maxAttempts {
            let result = await pvm.verifyWithCloudKit()
            guard result == .unavailable, attempt < maxAttempts else {
                return result
            }
            launchMessage = "> iCloud を再確認中..."
            try? await Task.sleep(for: .milliseconds(700))
            await cloudKit.checkAccountStatus()
        }
        return .unavailable
    }

    private func seedEnemiesOnce() async {
        let key = "enemiesSeededV1"
        guard cloudKit.isAvailable,
            !UserDefaults.standard.bool(forKey: key)
        else { return }
        do {
            try await cloudKit.seedEnemiesIfNeeded()
            UserDefaults.standard.set(true, forKey: key)
        } catch {}
    }
}
