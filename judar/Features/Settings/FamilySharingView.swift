import SwiftUI
import SwiftData

struct FamilySharingView: View {
    @Bindable var coordinator: CloudSharingCoordinator
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ファミリー共有")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtDimAmber)

            Button {
                Task { await coordinator.prepareShare(modelContext: modelContext) }
            } label: {
                Text("[ 家族と共有する ]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.crtAmber)
                    .padding(8)
                    .overlay(Rectangle().stroke(Color.crtAmber.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .alert("近日公開", isPresented: $coordinator.showingPhase1Alert) {
            Button("OK") {}
        } message: {
            Text("別 iCloud アカウント間のファミリー共有は\n次バージョンで対応予定です。")
        }
    }
}
