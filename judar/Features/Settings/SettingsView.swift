import AuthenticationServices
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(BattleViewModel.self) private var battleVM
    @Environment(ProfileViewModel.self) private var profileVM
    @Environment(AuthService.self) private var authSvc
    @Environment(ThemeManager.self) private var themeManager

    @Query(sort: \BabyEventRecord.timestamp, order: .reverse)
    private var records: [BabyEventRecord]

    @State private var isSyncing = false
    @State private var lastSyncMessage: String?

    private var unsyncedCount: Int {
        records.filter { !$0.isSynced }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rpgBackground.ignoresSafeArea()

                List {
                    Section {
                        themePicker
                    } header: {
                        sectionHeader("テーマ")
                    }

                    Section {
                        infoRow(label: "バージョン", value: appVersion)
                        infoRow(
                            label: "iCloud 同期",
                            value: profileVM.isCloudKitAvailable ? "有効" : "準備中"
                        )
                    } header: {
                        sectionHeader("アプリ情報")
                    }

                    Section {
                        syncOptimizeRow
                    } header: {
                        sectionHeader("データ管理")
                    }

                    if authSvc.isGuest {
                        Section {
                            guestSignInRow
                        } header: {
                            sectionHeader("アカウント")
                        }
                    }

                    Section {
                        FamilySharingView()
                            .padding(.vertical, 4)
                    } header: {
                        sectionHeader("家族")
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("[閉じる]") { dismiss() }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.rpgGold)
                }
            }
        }
    }

    // MARK: - Sync optimize row

    private var syncOptimizeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status line
            HStack(spacing: 0) {
                Text("未同期レコード")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.rpgGoldDim)
                Spacer()
                if unsyncedCount > 0 {
                    Text("\(unsyncedCount) 件")
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundColor(.rpgDanger)
                } else {
                    Text("なし")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.rpgGoldDim)
                }
            }

            // Action button
            Button {
                runSync()
            } label: {
                HStack(spacing: 8) {
                    if isSyncing {
                        ProgressView()
                            .tint(Color.rpgBackground)
                            .scaleEffect(0.8)
                        Text("同期中...")
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("全件アップロード")
                    }
                }
                .font(.system(.caption, design: .monospaced).bold())
                .foregroundStyle(
                    canSync ? Color.rpgBackground : Color.rpgGoldDim
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(canSync ? Color.rpgGold : Color.rpgSurface)
                .overlay(
                    Rectangle().stroke(
                        canSync ? Color.clear : Color.rpgBorder.opacity(0.4),
                        lineWidth: 1
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSync)

            // Result / hint message
            if let msg = lastSyncMessage {
                Text("> \(msg)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.rpgGoldDim)
            } else if !profileVM.isCloudKitAvailable {
                Text("> iCloud が有効になると同期できます")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.rpgGoldDim.opacity(0.7))
            }
        }
        .padding(.vertical, 6)
        .listRowBackground(Color.rpgSurface)
    }

    private var canSync: Bool {
        profileVM.isCloudKitAvailable && !isSyncing
            && !profileVM.familyId.isEmpty
    }

    private func runSync() {
        guard canSync else { return }
        isSyncing = true
        lastSyncMessage = nil
        let snapshot = records
        Task {
            await battleVM.pushAllPending(
                records: snapshot,
                familyId: profileVM.familyId,
                userId: profileVM.userId
            )
            let remaining = snapshot.filter { !$0.isSynced }.count
            lastSyncMessage =
                remaining == 0
                ? "完了 — 全件同期済み"
                : "完了 — \(remaining) 件が未同期のままです"
            isSyncing = false
        }
    }

    // MARK: - Theme picker

    private var themePicker: some View {
        HStack {
            Text("外観")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.rpgGoldDim)
            Spacer()
            Picker("", selection: Bindable(themeManager).current) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .tint(.rpgGold)
        }
        .listRowBackground(Color.rpgSurface)
    }

    // MARK: - Guest → sign-in upgrade

    private var guestSignInRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apple ID でサインインすると\nデータのバックアップと家族共有が使えます")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.rpgGoldDim)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = []
            } onCompletion: { result in
                if case .success(let authorization) = result,
                    let cred = authorization.credential
                        as? ASAuthorizationAppleIDCredential
                {
                    authSvc.handleSignIn(userId: cred.user)
                    Task { await profileVM.upgradeFromGuest() }
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 40)
        }
        .listRowBackground(Color.rpgSurface)
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.rpgGold)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.rpgGoldDim)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.rpgGold)
        }
        .listRowBackground(Color.rpgSurface)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0"
    }
}
