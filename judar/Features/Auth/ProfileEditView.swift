import SwiftUI

struct ProfileEditView: View {
    @Environment(ProfileViewModel.self) private var profileVM
    let onComplete: () -> Void

    @State private var username = ""
    @State private var birthday =
        Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var gender: ChildGender = .male
    @State private var isSaving = false
    @State private var saveError: String? = nil

    var body: some View {
        ZStack {
            Color.rpgBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    fieldBlock(label: "ユーザ名（10文字まで）") {
                        TextField("", text: $username)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.crtAmber)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: username) { _, new in
                                if new.count > 10 {
                                    username = String(new.prefix(10))
                                }
                            }
                            .padding(8)
                            .overlay(
                                Rectangle().stroke(
                                    Color.crtAmber.opacity(0.5),
                                    lineWidth: 1
                                )
                            )
                    }

                    fieldBlock(label: "お子さんの生年月日") {
                        DatePicker(
                            "",
                            selection: $birthday,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.rpgGold)
                    }

                    fieldBlock(label: "性別") {
                        genderPicker
                    }

                    saveButton
                }
                .padding(24)
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("> プロフィール設定")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.crtAmber)
            Text("あとから設定画面で変更できます")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.crtDimAmber)
        }
    }

    private var genderPicker: some View {
        HStack(spacing: 0) {
            ForEach(ChildGender.allCases, id: \.self) { g in
                let selected = (gender == g)
                Button {
                    gender = g
                } label: {
                    Text(g.displayName)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(selected ? .black : .crtAmber)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected ? Color.crtAmber : Color.clear)
                        .overlay(
                            Rectangle().stroke(Color.crtAmber, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var saveButton: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let err = saveError {
                Text("> \(err)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.rpgDanger)
            }

            Button {
                Task { await save() }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView().tint(.black).scaleEffect(0.8)
                    }
                    Text(isSaving ? "[ 登録中... ]" : "[ はじめる ]")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(isButtonActive ? .black : .crtDimAmber)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(isButtonActive ? Color.crtAmber : Color.clear)
                .overlay(
                    Rectangle().stroke(
                        isButtonActive ? Color.crtAmber : Color.crtDimAmber,
                        lineWidth: 1
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(!isButtonActive)
            .padding(.top, 8)
        }
    }

    private var isButtonActive: Bool { canSave && !isSaving }

    private var canSave: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() async {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        if profileVM.profile == nil {
            // New user — create profile and confirm CloudKit write before proceeding.
            do {
                try await profileVM.createAndPushProfile(
                    username: username,
                    birthday: birthday,
                    gender: gender
                )
            } catch {
                saveError = "iCloud への登録に失敗しました。再試行してください。"
                return
            }
        } else {
            // Existing user editing profile — local update only.
            profileVM.updateProfile(
                username: username,
                birthday: birthday,
                gender: gender
            )
        }

        onComplete()
    }

    // MARK: - Helper

    private func fieldBlock<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtDimAmber)
            content()
        }
    }
}
