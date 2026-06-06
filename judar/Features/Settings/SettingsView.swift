import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sharingCoordinator = CloudSharingCoordinator()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    Section {
                        infoRow(label: "バージョン", value: appVersion)
                        infoRow(label: "iCloud 同期", value: "有効")
                    } header: {
                        sectionHeader("アプリ情報")
                    }

                    Section {
                        FamilySharingView(coordinator: sharingCoordinator)
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
        }
    }

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
