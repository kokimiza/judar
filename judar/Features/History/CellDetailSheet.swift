import SwiftUI

struct CellDetailSheet: View {
    let records: [BabyEventRecord]
    let cell: GridCell
    let onDelete: (BabyEventRecord) -> Void
    let onRetry: ((BabyEventRecord) async -> Void)?

    @State private var editingRecord: BabyEventRecord?
    @Environment(\.dismiss) private var dismiss

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var sorted: [BabyEventRecord] {
        records.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rpgBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Slot summary header
                    HStack(spacing: 0) {
                        Text("> \(records.count) 件の記録")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.rpgGoldDim)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.rpgSurface.opacity(0.5))
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.rpgBorder.opacity(0.35)).frame(
                            height: 1
                        )
                    }

                    if records.isEmpty {
                        Spacer()
                        Text("> 記録がありません")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.rpgGoldDim)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(sorted, id: \.id) { record in
                                    recordRow(record)
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle(cellTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("[閉じる]") { dismiss() }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.rpgGold)
                }
            }
        }
        .sheet(item: $editingRecord) { record in
            EventEditSheet(
                record: record,
                onDelete: {
                    onDelete(record)
                    if records.count <= 1 { dismiss() }
                },
                onRetry: onRetry.map { fn in { await fn(record) } }
            )
        }
    }

    // MARK: - Record row

    private func recordRow(_ record: BabyEventRecord) -> some View {
        let et = record.eventType
        return HStack(spacing: 0) {
            // Accent bar
            Rectangle()
                .fill(et?.accentColor ?? Color.rpgGoldDim)
                .frame(width: 3)

            HStack(spacing: 12) {
                Image(systemName: et?.icon ?? "questionmark")
                    .font(.system(size: 22))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(et?.displayName ?? "不明")
                            .font(.system(.callout, design: .monospaced).bold())
                            .foregroundColor(.rpgGold)

                        if et == .formula, record.amount > 0 {
                            Text("\(record.amount) ml")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(EventType.formula.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(
                                    Rectangle()
                                        .stroke(
                                            EventType.formula.accentColor
                                                .opacity(0.55),
                                            lineWidth: 1
                                        )
                                )
                        }
                    }

                    HStack(spacing: 5) {
                        Text(Self.timeFmt.string(from: record.timestamp))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.rpgGoldDim)
                        if !record.isSynced {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.rpgDanger)
                        }
                    }
                }

                Spacer()

                Button {
                    editingRecord = record
                } label: {
                    Text("[編集]")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.rpgGoldDim)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color.rpgSurface)
        .overlay(
            Rectangle().stroke(Color.rpgBorder.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Title

    private var cellTitle: String {
        let cal = Calendar.current
        let m = cal.component(.month, from: cell.day)
        let d = cal.component(.day, from: cell.day)
        let hour = cell.slot / 2
        let min = (cell.slot % 2) * 30
        return String(format: "%d/%d  %02d:%02d", m, d, hour, min)
    }
}
