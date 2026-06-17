import OSLog
import SwiftData
import SwiftUI

private let bvlog = Logger(
    subsystem: "productions.jocarium.judar",
    category: "BattleView"
)

// MARK: - BattleView

struct BattleView: View {
    @Environment(BattleViewModel.self) private var vm
    @Environment(ProfileViewModel.self) private var profileVM
    @Environment(AuthService.self) private var authSvc
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LaunchCoordinator.self) private var coordinator
    @Query(sort: \BabyEventRecord.timestamp, order: .reverse)
    private var records: [BabyEventRecord]

    @State private var attackingType: EventType? = nil
    @State private var enemyFlashing = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showFormulaSheet = false
    @State private var formulaAmount: Int = 5
    @State private var showPumpedMilkSheet = false
    @State private var pumpedMilkAmount: Int = 5

    private var todayCounts: DailyCounts {
        DailyStats.counts(
            from: records.compactMap { $0.toEventRecord() },
            for: .now
        )
    }

    var body: some View {
        ZStack {
            Color.rpgBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                crtLine

                Spacer(minLength: 0)

                EnemyView(
                    enemy: vm.battleState.enemy,
                    isFlashing: enemyFlashing
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 0)

                MiracleClockView(events: records)

                Spacer(minLength: 0)

                BattleLogView(lines: vm.battleState.battleLog)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                crtLine

                eventGrid
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
        }
        .sheet(isPresented: $showHistory) { HistoryView() }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(vm)
                .environment(profileVM)
                .environment(authSvc)
                .environment(themeManager)
                .environment(coordinator)
        }
        .sheet(isPresented: $showFormulaSheet) {
            MilkAmountSheet(title: "> ミルク量を選択", amount: $formulaAmount) {
                fireEvent(.formula, amount: formulaAmount)
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPumpedMilkSheet) {
            MilkAmountSheet(title: "> 搾乳量を選択", amount: $pumpedMilkAmount) {
                fireEvent(.pumpedMilk, amount: pumpedMilkAmount)
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: vm.battleState.enemy.currentHP) { old, new in
            if new < old { triggerEnemyFlash() }
        }
        .sensoryFeedback(.success, trigger: vm.battleState.killStreak)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 0) {
            Text("討伐 \(vm.battleState.killStreak)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.rpgGoldDim)

            Spacer()

            partyHPBadge

            Spacer()

            HStack(spacing: 14) {
                Button {
                    showHistory = true
                } label: {
                    Text("[LOG]")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.rpgGoldDim)
                }
                Button {
                    showSettings = true
                } label: {
                    Text("[SET]")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.rpgGoldDim)
                }
            }
        }
    }

    private var partyHPBadge: some View {
        let hp = vm.battleState.partyHP
        let fraction = Double(hp) / Double(BattleState.initialPartyHP)
        let hpColor: Color =
            fraction > 0.5 ? .rpgGold : fraction > 0.25 ? .yellow : .rpgDanger
        return HStack(spacing: 4) {
            Text("PARTY HP")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.rpgGoldDim)
            Text("\(hp)")
                .font(.system(size: 12, design: .monospaced).bold())
                .foregroundColor(hpColor)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: hp)
        }
    }

    // MARK: - Event grid

    private var eventGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 8
        ) {
            EventButton(
                eventType: .diaper,
                count: todayCounts[.diaper],
                isAttacking: attackingType == .diaper
            ) { fireEvent(.diaper) }

            EventButton(
                eventType: .breastfeed,
                count: todayCounts[.breastfeed],
                isAttacking: attackingType == .breastfeed
            ) { fireEvent(.breastfeed) }

            MilkEventButton(
                eventType: .formula,
                count: todayCounts[.formula],
                amount: formulaAmount,
                isAttacking: attackingType == .formula
            ) { showFormulaSheet = true }

            MilkEventButton(
                eventType: .pumpedMilk,
                count: todayCounts[.pumpedMilk],
                amount: pumpedMilkAmount,
                isAttacking: attackingType == .pumpedMilk
            ) { showPumpedMilkSheet = true }
        }
    }

    // MARK: - Helpers

    private var crtLine: some View {
        Rectangle()
            .fill(Color.rpgBorder.opacity(0.4))
            .frame(height: 1)
    }

    private func fireEvent(_ eventType: EventType, amount: Int = 0) {
        bvlog.debug(
            "▶ tap type=\(eventType.rawValue, privacy: .public) amount=\(amount) familyId=\(profileVM.familyId.isEmpty ? "<empty>" : String(profileVM.familyId.prefix(8)), privacy: .public)… userId=\(profileVM.userId.isEmpty ? "<empty>" : String(profileVM.userId.prefix(8)), privacy: .public)…"
        )
        attackingType = eventType
        vm.logEvent(
            eventType,
            amount: amount,
            familyId: profileVM.familyId,
            userId: profileVM.userId
        )
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            attackingType = nil
        }
    }

    private func triggerEnemyFlash() {
        enemyFlashing = true
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            enemyFlashing = false
        }
    }
}

// MARK: - EventButton

private struct EventButton: View {
    let eventType: EventType
    let count: Int
    let isAttacking: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var isActive: Bool { isPressed || isAttacking }

    var body: some View {
        Button {
            isPressed = true
            action()
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                isPressed = false
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: eventType.icon)
                    .font(.system(size: 28))
                Text(eventType.displayName)
                    .font(.system(.callout, design: .monospaced).bold())
                Text("\(count)回")
                    .font(.system(size: 11, design: .monospaced))
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .foregroundColor(isActive ? .black : .rpgGold)
            .background(isActive ? Color.rpgGold : Color.rpgSurface)
            .overlay(
                Rectangle().stroke(
                    isActive ? Color.rpgGold : Color.rpgBorder.opacity(0.6),
                    lineWidth: 1
                )
            )
            .animation(.easeOut(duration: 0.1), value: isActive)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed) {
            _,
            new in new
        }
    }
}

// MARK: - MilkEventButton (formula & pumpedMilk — both track ml)

private struct MilkEventButton: View {
    let eventType: EventType
    let count: Int
    let amount: Int
    let isAttacking: Bool
    var compact: Bool = false
    let onTap: () -> Void

    @State private var isPressed = false
    private var isActive: Bool { isPressed || isAttacking }

    var body: some View {
        Button {
            isPressed = true
            onTap()
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                isPressed = false
            }
        } label: {
            HStack(spacing: compact ? 12 : 0) {
                if compact {
                    Image(systemName: eventType.icon)
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(eventType.displayName)
                            .font(.system(.callout, design: .monospaced).bold())
                        Text("\(count)回  \(amount) ml")
                            .font(.system(size: 10, design: .monospaced))
                            .opacity(0.75)
                    }
                } else {
                    VStack(spacing: 5) {
                        Image(systemName: eventType.icon)
                            .font(.system(size: 28))
                        Text(eventType.displayName)
                            .font(.system(.callout, design: .monospaced).bold())
                        Text("\(count)回")
                            .font(.system(size: 11, design: .monospaced))
                        Text("\(amount) ml")
                            .font(.system(size: 10, design: .monospaced))
                            .opacity(0.65)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 52 : 104)
            .foregroundColor(isActive ? .black : .rpgGold)
            .background(isActive ? Color.rpgGold : Color.rpgSurface)
            .overlay(
                Rectangle().stroke(
                    isActive ? Color.rpgGold : Color.rpgBorder.opacity(0.6),
                    lineWidth: 1
                )
            )
            .animation(.easeOut(duration: 0.1), value: isActive)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed) {
            _,
            new in new
        }
    }
}

// MARK: - MilkAmountSheet (shared by formula & pumpedMilk)

private struct MilkAmountSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var amount: Int
    let onConfirm: () -> Void

    static let amounts: [Int] =
        [5] + Array(stride(from: 10, through: 220, by: 10))

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.rpgGold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            Picker("量", selection: $amount) {
                ForEach(Self.amounts, id: \.self) { ml in
                    Text("\(ml) ml")
                        .font(.system(.body, design: .monospaced))
                        .tag(ml)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .tint(.rpgGold)

            Button {
                onConfirm()
                dismiss()
            } label: {
                Text("[ 記録する ]")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.rpgGold)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color.rpgBackground.ignoresSafeArea())
    }
}
