import SwiftUI
import UIKit

struct EventEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var record: BabyEventRecord
    let onDelete: () -> Void
    let onRetry: (() async -> Void)?

    @State private var editTime: Date
    @State private var editType: EventType
    @State private var editAmount: Int
    @State private var showDeleteAlert = false
    @State private var isRetrying = false
    @State private var retryOutcome: RetryOutcome? = nil

    private enum RetryOutcome {
        case unavailable  // CloudKit 到達不可（ゲスト / オフライン）
        case failed  // syncErrorRaw にエラーが記録された
    }

    private static let formulaAmounts: [Int] =
        [5] + Array(stride(from: 10, through: 220, by: 10))

    init(
        record: BabyEventRecord,
        onDelete: @escaping () -> Void,
        onRetry: (() async -> Void)? = nil
    ) {
        self.record = record
        self.onDelete = onDelete
        self.onRetry = onRetry
        _editTime = State(initialValue: record.timestamp)
        _editType = State(initialValue: record.eventType ?? .diaper)
        _editAmount = State(initialValue: record.amount > 0 ? record.amount : 5)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rpgBackground.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 28) {
                    if !record.isSynced {
                        syncErrorBanner
                    }

                    fieldBlock(label: "日時") {
                        DatePicker(
                            "",
                            selection: $editTime,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.rpgGold)
                    }

                    fieldBlock(label: "種別") {
                        HStack(spacing: 0) {
                            ForEach(EventType.allCases, id: \.self) { et in
                                let selected = (editType == et)
                                Button {
                                    editType = et
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: et.icon).font(.title2)
                                        Text(et.displayName)
                                            .font(
                                                .system(
                                                    size: 9,
                                                    design: .monospaced
                                                )
                                            )
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 60)
                                    .foregroundColor(
                                        selected ? .black : .rpgGold
                                    )
                                    .background(
                                        selected ? Color.rpgGold : Color.clear
                                    )
                                    .overlay(
                                        Rectangle().stroke(
                                            Color.rpgBorder.opacity(0.6),
                                            lineWidth: 1
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if editType == .formula {
                        fieldBlock(label: "ミルク量") {
                            Picker("ミルク量", selection: $editAmount) {
                                ForEach(Self.formulaAmounts, id: \.self) { ml in
                                    Text("\(ml) ml").tag(ml)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .tint(.rpgGold)
                        }
                    }

                    Button {
                        record.timestamp = editTime
                        record.eventTypeRaw = editType.rawValue
                        record.amount = (editType == .formula) ? editAmount : 0
                        record.isSynced = false
                        dismiss()
                    } label: {
                        Text("[ 保存する ]")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.rpgGold)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("> 記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("[キャンセル]") { dismiss() }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.rpgGoldDim)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.rpgDanger)
                    }
                }
            }
            .alert("この記録を削除しますか？", isPresented: $showDeleteAlert) {
                Button("削除する", role: .destructive) {
                    UINotificationFeedbackGenerator().notificationOccurred(
                        .warning
                    )
                    onDelete()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("削除した記録は元に戻せません")
            }
        }
    }

    // MARK: - Sync error banner

    private var syncErrorBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            // タイトル行
            HStack(spacing: 6) {
                Image(systemName: bannerIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(bannerTitleColor)
                Text(bannerTitle)
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundStyle(bannerTitleColor)
            }
            // 本文
            Text(bannerBody)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.rpgGoldDim)
                .fixedSize(horizontal: false, vertical: true)

            // 再試行ボタン（到達不可の確定後は非表示）
            if let onRetry, retryOutcome != .unavailable {
                Button {
                    isRetrying = true
                    retryOutcome = nil
                    Task {
                        await onRetry()
                        if record.isSynced {
                            // バナー自体が消えるので何もしない
                        } else if !record.syncErrorRaw.isEmpty {
                            retryOutcome = .failed
                        } else {
                            retryOutcome = .unavailable
                        }
                        isRetrying = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isRetrying {
                            ProgressView().tint(Color.rpgGold).scaleEffect(0.75)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRetrying ? "再試行中..." : "[ 再試行 ]")
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(
                        isRetrying ? Color.rpgGoldDim : Color.rpgGold
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .overlay(
                        Rectangle().stroke(
                            Color.rpgBorder.opacity(0.6),
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRetrying)
            }
        }
        .padding(12)
        .background(bannerBg)
        .overlay(Rectangle().stroke(bannerBorderColor, lineWidth: 1))
    }

    // MARK: - Banner appearance helpers

    private var bannerIcon: String {
        retryOutcome == .unavailable
            ? "icloud.slash.fill" : "exclamationmark.triangle.fill"
    }

    private var bannerTitleColor: Color {
        retryOutcome == .unavailable ? Color.rpgGoldDim : Color.rpgDanger
    }

    private var bannerTitle: String {
        switch retryOutcome {
        case .unavailable: return "> iCloud 未接続"
        case .failed: return "> 同期エラー"
        case nil:
            return record.syncErrorRaw.isEmpty ? "> 未アップロード" : "> 同期エラー"
        }
    }

    private var bannerBody: String {
        switch retryOutcome {
        case .unavailable:
            return
                "ゲストモードまたはオフラインのため送信できません。\nApple ID でサインインし iCloud を有効にすると自動で同期されます。"
        case .failed:
            return record.syncErrorRaw
        case nil:
            return record.syncErrorRaw.isEmpty
                ? "CloudKit に送信されていません"
                : record.syncErrorRaw
        }
    }

    private var bannerBg: Color {
        retryOutcome == .unavailable
            ? Color.rpgGoldDim.opacity(0.08)
            : Color.rpgDanger.opacity(0.08)
    }

    private var bannerBorderColor: Color {
        retryOutcome == .unavailable
            ? Color.rpgGoldDim.opacity(0.3)
            : Color.rpgDanger.opacity(0.35)
    }

    private func fieldBlock<C: View>(
        label: String,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.rpgGoldDim)
            content()
        }
    }
}
