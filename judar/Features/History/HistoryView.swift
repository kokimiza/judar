import SwiftData
import SwiftUI

// MARK: - HistoryView

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BabyEventRecord.timestamp, order: .reverse)
    private var records: [BabyEventRecord]

    @State private var dayRange: Int = 3
    @State private var selectedCell: GridCell?

    // Async index state
    @Environment(BattleViewModel.self) private var battleVM
    @Environment(ProfileViewModel.self) private var profileVM

    @State private var countIdx: [String: Int] = [:]
    @State private var unsyncIdx: Set<String> = []
    @State private var isReady: Bool = false
    @State private var isReindexing: Bool = false
    @State private var indexingTask: Task<Void, Never>?

    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<dayRange)
            .map { cal.date(byAdding: .day, value: -$0, to: today)! }
            .reversed()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rpgBackground.ignoresSafeArea()
                if isReady {
                    mainContent
                        .transition(.opacity)
                } else {
                    loadingView
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: isReady)
            .navigationTitle("記録ログ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("[閉じる]") { dismiss() }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.rpgGold)
                }
            }
        }
        .sheet(item: $selectedCell) { cell in
            CellDetailSheet(
                records: events(for: cell),
                cell: cell,
                onDelete: { modelContext.delete($0) },
                onRetry: { record in
                    await battleVM.retrySync(
                        record: record,
                        familyId: profileVM.familyId,
                        userId: profileVM.userId
                    )
                }
            )
        }
        .task { scheduleReindex(initial: true) }
        .onChange(of: dayRange) { _, _ in scheduleReindex() }
        .onChange(of: records.count) { _, _ in scheduleReindex() }
    }

    // MARK: - Main content

    private var mainContent: some View {
        VStack(spacing: 0) {
            rangeSelector
            crtLine
            HistoryTimeGrid(
                days: days,
                countIdx: countIdx,
                unsyncIdx: unsyncIdx
            ) { cell in
                selectedCell = cell
            }
        }
    }

    // MARK: - Loading views

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().tint(.crtAmber)
            Text("> 読み込み中...")
                .font(.system(.callout, design: .monospaced))
                .foregroundColor(.crtAmber)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Range selector

    private var rangeSelector: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach([1, 3, 7], id: \.self) { n in
                    let active = dayRange == n
                    Button {
                        dayRange = n
                    } label: {
                        HStack(spacing: 4) {
                            Image(
                                systemName: active
                                    ? "\(n).circle.fill" : "\(n).circle"
                            )
                            .font(.system(size: 13, weight: .semibold))
                            Text("\(n)日")
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .semibold,
                                        design: .monospaced
                                    )
                                )
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(
                            active ? Color.rpgBackground : Color.rpgGoldDim
                        )
                        .background(
                            active ? Color.rpgGold : Color.clear,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: active)
                }
            }
            .padding(3)
            .background(
                Color.rpgSurface,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20).strokeBorder(
                    Color.rpgBorder.opacity(0.4),
                    lineWidth: 1
                )
            )
            .padding(.leading, 10)
            .padding(.vertical, 6)

            Spacer()

            if isReindexing {
                ProgressView()
                    .tint(.crtAmber)
                    .scaleEffect(0.7)
                    .padding(.trailing, 10)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isReindexing)
    }

    // MARK: - Helpers

    private var crtLine: some View {
        Rectangle().fill(Color.crtAmber.opacity(0.2)).frame(height: 1)
    }

    private func events(for cell: GridCell) -> [BabyEventRecord] {
        let cal = Calendar.current
        return records.filter { r in
            let day = cal.startOfDay(for: r.timestamp)
            let h = cal.component(.hour, from: r.timestamp)
            let m = cal.component(.minute, from: r.timestamp)
            let slot = h * 2 + (m >= 30 ? 1 : 0)
            return day == cell.day && slot == cell.slot
        }
    }

    // MARK: - Async index

    private func scheduleReindex(initial: Bool = false) {
        indexingTask?.cancel()
        if initial {
            isReady = false
        } else {
            isReindexing = true
        }
        indexingTask = Task { await reindex(initial: initial) }
    }

    private func reindex(initial: Bool) async {
        // Yield immediately so the UI (selector animation etc.) can update
        // before any work begins.
        await Task.yield()

        // Capture only raw values on MainActor — no Calendar calls here.
        struct Raw: Sendable {
            let timestamp: Date
            let typeRaw: String
            let isSynced: Bool
        }
        let rawData: [Raw] = records.map {
            Raw(
                timestamp: $0.timestamp,
                typeRaw: $0.eventTypeRaw,
                isSynced: $0.isSynced
            )
        }

        // All Calendar work runs off MainActor.
        let (newIdx, newUnsync) = await Task.detached(priority: .userInitiated)
        {
            let cal = Calendar.current
            var idx: [String: Int] = [:]
            var unsync = Set<String>()
            for r in rawData {
                let dayStart = cal.startOfDay(for: r.timestamp)
                    .timeIntervalSince1970
                let h = cal.component(.hour, from: r.timestamp)
                let m = cal.component(.minute, from: r.timestamp)
                let slot = h * 2 + (m >= 30 ? 1 : 0)
                let key = "\(dayStart)_\(slot)_\(r.typeRaw)"
                idx[key, default: 0] += 1
                if !r.isSynced { unsync.insert(key) }
            }
            return (idx, unsync)
        }.value

        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.15)) {
            countIdx = newIdx
            unsyncIdx = newUnsync
            if initial { isReady = true } else { isReindexing = false }
        }
    }
}
