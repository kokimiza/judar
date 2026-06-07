import SwiftUI

struct FamilySharingView: View {
    @Environment(ProfileViewModel.self) private var profileVM
    @State private var showJoin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ファミリー共有")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtDimAmber)

            if profileVM.isLoading {
                Text("読込中...")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.crtDimAmber)
            } else {
                infoRow(label: "ユーザーID",  value: profileVM.userId)
                infoRow(label: "共有コード",   value: profileVM.shareCode)

                Button {
                    showJoin = true
                } label: {
                    Text("[ ファミリーに合流する ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.crtAmber)
                        .padding(8)
                        .overlay(Rectangle().stroke(Color.crtAmber.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showJoin) {
            JoinFamilyView()
                .environment(profileVM)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.crtDimAmber)
            HStack(spacing: 8) {
                Text(value.isEmpty ? "---" : value)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.crtAmber)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !value.isEmpty {
                    Button {
                        UIPasteboard.general.string = value
                    } label: {
                        Text("[コピー]")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.crtDimAmber)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
