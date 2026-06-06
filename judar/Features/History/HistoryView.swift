import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BabyEventRecord.timestamp, order: .reverse)
    private var records: [BabyEventRecord]

    @State private var vm = HistoryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    ForEach(vm.groupedDays, id: \.day) { group in
                        Section {
                            DailyCountSummaryRow(counts: group.counts)
                            ForEach(group.records, id: \.timestamp) { record in
                                EventHistoryRow(record: record)
                            }
                        } header: {
                            Text(vm.dayLabel(for: group.day))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.crtAmber)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("記録ログ")
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
        .onAppear { vm.load(records: records) }
        .onChange(of: records.count) { _, _ in vm.load(records: records) }
    }
}

// MARK: - Subviews

private struct DailyCountSummaryRow: View {
    let counts: DailyCounts

    var body: some View {
        HStack(spacing: 12) {
            ForEach(EventType.allCases, id: \.self) { et in
                Text("\(et.displayName):\(counts[et])")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.crtDimAmber)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.black)
    }
}

private struct EventHistoryRow: View {
    let record: EventRecord

    var body: some View {
        HStack {
            Text(timeLabel)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtDimAmber)
            Text(record.eventType.displayName)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtAmber)
            Text(record.eventType.partyMember.name + " こうどう")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.crtDimAmber)
        }
        .listRowBackground(Color.black)
    }

    private var timeLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: record.timestamp)
    }
}
