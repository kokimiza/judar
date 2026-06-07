import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProfileViewModel.self) private var profileVM
    @Environment(AuthService.self) private var authSvc

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    Section {
                        infoRow(label: "バージョン", value: appVersion)
                        infoRow(label: "iCloud 同期", value: profileVM.cloudKit.isAvailable ? "有効" : "準備中")
                    } header: {
                        sectionHeader("アプリ情報")
                    }

                    // Show sign-in prompt only when running in guest mode
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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("[閉じる]") { dismiss() }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.crtAmber)
                }
            }
            .task { await profileVM.loadOrCreate() }
        }
    }

    // MARK: - Guest → sign-in upgrade

    private var guestSignInRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apple ID でサインインすると\nデータのバックアップと家族共有が使えます")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.crtDimAmber)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = []
            } onCompletion: { result in
                if case .success(let authorization) = result,
                   let cred = authorization.credential as? ASAuthorizationAppleIDCredential {
                    authSvc.handleSignIn(userId: cred.user)
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 40)
        }
        .listRowBackground(Color.black)
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.crtAmber)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtDimAmber)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtAmber)
        }
        .listRowBackground(Color.black)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
