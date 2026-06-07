import SwiftUI
import SwiftData

private enum AppPhase {
    case checking
    case signIn
    case profileSetup
    case home
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var appPhase  = AppPhase.checking
    @State private var authSvc   = AuthService()
    @State private var cloudKit  = CloudKitSyncService()
    @State private var battleVM: BattleViewModel?
    @State private var profileVM: ProfileViewModel?

    var body: some View {
        Group {
            switch appPhase {
            case .checking:
                Color.black.ignoresSafeArea()
                    .task { await checkAuth() }

            case .signIn:
                SignInView()
                    .environment(authSvc)

            case .profileSetup:
                if let pvm = profileVM {
                    ProfileEditView { appPhase = .home }
                        .environment(pvm)
                }

            case .home:
                if let bvm = battleVM, let pvm = profileVM {
                    BattleView()
                        .environment(bvm)
                        .environment(pvm)
                        .environment(authSvc)
                }
            }
        }
        // Boot services when Apple sign-in OR guest mode is chosen
        .onChange(of: authSvc.canProceed) { _, can in
            guard can else { return }
            Task { await bootServices() }
        }
    }

    // MARK: - Auth check on launch

    private func checkAuth() async {
        // Guest mode persists across launches
        if authSvc.isGuest {
            await bootServices()
            return
        }
        let valid = await authSvc.checkStoredAuth()
        if valid {
            await bootServices()
        } else {
            appPhase = .signIn
        }
    }

    // MARK: - Service initialization (runs after successful auth)

    private func bootServices() async {
        let pvm = ProfileViewModel(modelContext: modelContext, cloudKit: cloudKit)
        let bvm = BattleViewModel(modelContext: modelContext, cloudKit: cloudKit)
        profileVM = pvm
        battleVM  = bvm

        await pvm.loadOrCreate()

        if cloudKit.isAvailable {
            try? await cloudKit.seedEnemiesIfNeeded()
        }

        appPhase = pvm.isProfileComplete ? .home : .profileSetup
    }
}
