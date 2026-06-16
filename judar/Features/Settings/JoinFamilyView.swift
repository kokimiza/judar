import SwiftUI

struct JoinFamilyView: View {
    @Environment(ProfileViewModel.self) private var profileVM
    @Environment(\.dismiss) private var dismiss

    @State private var ownerUserId = ""
    @State private var ownerShareCode = ""
    @State private var localError: Error?
    @State private var success = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rpgBackground.ignoresSafeArea()
                if success {
                    successView
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("相手のユーザーIDと\n共有コードを入力")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.crtAmber)

                        inputField(label: "ユーザーID", text: $ownerUserId)
                            .textInputAutocapitalization(.never)

                        inputField(label: "共有コード（6文字）", text: $ownerShareCode)
                            .textInputAutocapitalization(.characters)

                        if let err = localError {
                            Text(err.localizedDescription)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.crtRed)
                        }

                        Button {
                            Task { await join() }
                        } label: {
                            Group {
                                if profileVM.isJoiningFamily {
                                    Text("[ 確認中... ]")
                                } else {
                                    Text("[ 合流する ]")
                                }
                            }
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                canJoin ? Color.crtAmber : Color.crtDimAmber
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canJoin)

                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("ファミリー合流")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !success {
                        Button("[キャンセル]") { dismiss() }
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.crtDimAmber)
                    }
                }
            }
        }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("合流成功！")
                .font(.system(.title3, design: .monospaced))
                .foregroundColor(.crtAmber)

            Text("同じファミリーとして記録が共有されます。\n反映するにはアプリの再起動が必要です。")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtDimAmber)
                .multilineTextAlignment(.center)

            Button {
                exit(0)
            } label: {
                Text("[ 今すぐ再起動する ]")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.crtAmber)
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                Text("[ あとで再起動する ]")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.crtDimAmber)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(20)
    }

    // MARK: - Helpers

    private var canJoin: Bool {
        !ownerUserId.trimmingCharacters(in: .whitespaces).isEmpty
            && ownerShareCode.trimmingCharacters(in: .whitespaces).count == 6
            && !profileVM.isJoiningFamily
    }

    private func join() async {
        localError = nil
        do {
            try await profileVM.joinFamily(
                ownerUserId: ownerUserId.trimmingCharacters(in: .whitespaces),
                ownerShareCode: ownerShareCode
            )
            success = true
        } catch {
            localError = error
        }
    }

    private func inputField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtDimAmber)
            TextField("", text: text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.crtAmber)
                .autocorrectionDisabled()
                .padding(8)
                .overlay(
                    Rectangle().stroke(
                        Color.crtAmber.opacity(0.5),
                        lineWidth: 1
                    )
                )
        }
    }
}
