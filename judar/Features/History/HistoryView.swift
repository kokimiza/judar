import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BabyEventRecord.timestamp, order: .reverse)
    private var records: [BabyEventRecord]

    @State private var vm = HistoryViewModel()
    @State private var editingRecord: BabyEventRecord?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if vm.groupedDays.isEmpty {
                    Text("> 記録がありません")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.crtDimAmber)
                } else {
                    list
                }
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
        .sheet(item: $editingRecord) { record in
            EventEditSheet(record: record)
        }
        .onAppear { vm.load(records: records) }
        .onChange(of: records.count) { _, _ in vm.load(records: records) }
    }

    // MARK: - List

    private var list: some View {
        List {
            ForEach(vm.groupedDays, id: \.day) { group in
                Section {
                    DailySummaryRow(counts: group.counts)
                    ForEach(group.records, id: \.id) { record in
                        EventRow(record: record) {
                            editingRecord = record
                        }
                        // 右スワイプで削除
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(record)
                                vm.load(records: records)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(vm.dayLabel(for: group.day))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.crtAmber)
                        Spacer()
                        Text("計\(group.counts.total)回")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.crtDimAmber)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Daily summary row

private struct DailySummaryRow: View {
    let counts: DailyCounts

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EventType.allCases, id: \.self) { et in
                summaryCell(et)
                if et != EventType.allCases.last {
                    Divider()
                        .frame(height: 40)
                        .overlay(Color.crtAmber.opacity(0.15))
                }
            }
        }
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.03))
        .overlay(Rectangle().strokeBorder(Color.crtAmber.opacity(0.2), lineWidth: 1))
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.black)
    }

    private func summaryCell(_ et: EventType) -> some View {
        let count = counts[et]
        return VStack(spacing: 3) {
            Text(et.icon).font(.title3)
            Text("\(count)")
                .font(.system(.headline, design: .monospaced).bold())
                .foregroundColor(count > 0 ? .crtAmber : .crtDimAmber)
            Text(et.displayName)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.crtDimAmber)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - Event row (tappable, swipe-deletable)

private struct EventRow: View {
    let record: BabyEventRecord
    let onTap: () -> Void

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Text(Self.timeFmt.string(from: record.timestamp))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.crtDimAmber)
                    .frame(width: 44, alignment: .leading)

                Text(record.eventType?.icon ?? "?")
                    .font(.body)
                    .frame(width: 28, alignment: .center)

                Text(record.eventType?.displayName ?? "不明")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.crtAmber)

                Spacer()

                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundColor(.crtDimAmber)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.black)
    }
}

// MARK: - Edit sheet

private struct EventEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var record: BabyEventRecord

    @State private var editTime: Date
    @State private var editType: EventType

    init(record: BabyEventRecord) {
        self.record   = record
        _editTime     = State(initialValue: record.timestamp)
        _editType     = State(initialValue: record.eventType ?? .poop)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 28) {
                    // Date + time picker
                    fieldBlock(label: "日時") {
                        DatePicker("", selection: $editTime, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .tint(.crtAmber)
                    }

                    // Event type selector
                    fieldBlock(label: "種別") {
                        HStack(spacing: 0) {
                            ForEach(EventType.allCases, id: \.self) { et in
                                let selected = (editType == et)
                                Button {
                                    editType = et
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(et.icon).font(.title2)
                                        Text(et.displayName)
                                            .font(.system(size: 9, design: .monospaced))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor(selected ? .black : .crtAmber)
                                    .background(selected ? Color.crtAmber : Color.clear)
                                    .overlay(Rectangle().stroke(Color.crtAmber, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Save
                    Button {
                        record.timestamp    = editTime
                        record.eventTypeRaw = editType.rawValue
                        record.isSynced     = false  // re-sync on next push
                        dismiss()
                    } label: {
                        Text("[ 保存する ]")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.crtAmber)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("> 記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("[キャンセル]") { dismiss() }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.crtDimAmber)
                }
            }
        }
    }

    private func fieldBlock<C: View>(label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtDimAmber)
            content()
        }
    }
}
