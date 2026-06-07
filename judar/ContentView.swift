import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var coordinator = LaunchCoordinator()

    var body: some View {
        Group {
            switch coordinator.phase {
            case .checking:
                launchingView

            case .signIn:
                SignInView()
                    .environment(coordinator.authSvc)

            case .profileSetup:
                if let pvm = coordinator.profileVM {
                    ProfileEditView { coordinator.advanceToHome() }
                        .environment(pvm)
                }

            case .home:
                if let bvm = coordinator.battleVM,
                    let pvm = coordinator.profileVM
                {
                    BattleView()
                        .environment(bvm)
                        .environment(pvm)
                        .environment(coordinator.authSvc)
                }
            }
        }
        .task { await coordinator.start(modelContext: modelContext) }
        .onChange(of: coordinator.canProceed) { _, can in
            guard can, coordinator.phase == .signIn else { return }
            Task { await coordinator.bootServices(modelContext: modelContext) }
        }
        .preferredColorScheme(coordinator.themeManager.current.colorScheme)
        .environment(coordinator.themeManager)
    }

    // MARK: - Launch screen (UI only — logic lives in LaunchCoordinator)

    private var launchingView: some View {
        ZStack {
            Color.rpgBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 8) {
                    Text("judar")
                        .font(.system(size: 48, design: .monospaced).bold())
                        .foregroundColor(.rpgGold)
                    Text("赤ちゃん育児記録 RPG")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.rpgGoldDim)
                }
                Spacer()
                if coordinator.cloudKitVerifyFailed {
                    cloudKitErrorPanel
                } else {
                    VStack(spacing: 10) {
                        ProgressView().tint(.rpgGold)
                        Text(coordinator.launchMessage)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.rpgGoldDim)
                            .animation(
                                .easeOut,
                                value: coordinator.launchMessage
                            )
                    }
                }
                Spacer().frame(height: 48)
            }
        }
    }

    private var cloudKitErrorPanel: some View {
        VStack(spacing: 14) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 32))
                .foregroundColor(.rpgGoldDim)
            Text("iCloud に接続できません")
                .font(.system(.caption, design: .monospaced).bold())
                .foregroundColor(.rpgGoldDim)
            Text("プロフィール確認にはネットワーク接続が必要です")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.rpgGoldDim.opacity(0.6))
                .multilineTextAlignment(.center)
            Button {
                Task {
                    await coordinator.retryCloudKitVerification(
                        modelContext: modelContext
                    )
                }
            } label: {
                Text("[ 再接続 ]")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(.rpgGold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .overlay(
                        Rectangle().stroke(
                            Color.rpgBorder.opacity(0.6),
                            lineWidth: 1
                        )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
    }
}
