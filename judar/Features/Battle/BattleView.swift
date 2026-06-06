import SwiftUI
import SwiftData

// MARK: - CRT Color Theme

extension Color {
    static let crtAmber    = Color(red: 1.0, green: 0.71, blue: 0.0)
    static let crtDimAmber = Color(red: 1.0, green: 0.71, blue: 0.0).opacity(0.45)
    static let crtRed      = Color(red: 1.0, green: 0.25, blue: 0.20)
}

// MARK: - BattleView

struct BattleView: View {
    @Environment(BattleViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BabyEventRecord.timestamp, order: .reverse)
    private var records: [BabyEventRecord]

    @State private var attackingType: EventType? = nil
    @State private var enemyFlashing = false
    @State private var showHistory   = false
    @State private var showSettings  = false
    @State private var prevEnemyHP: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                topBar
                Spacer(minLength: 0)
                EnemyView(enemy: vm.battleState.enemy, isFlashing: enemyFlashing)
                Spacer(minLength: 0)
                BattleLogView(lines: vm.battleState.battleLog)
                PartyView(todayCounts: vm.todayCounts(from: records), attackingType: attackingType)
                eventGrid
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showHistory)  { HistoryView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear { prevEnemyHP = vm.battleState.enemy.currentHP }
        .onChange(of: vm.battleState.enemy.currentHP) { old, new in
            if new < old { triggerEnemyFlash() }
            prevEnemyHP = new
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Text("連続討伐: \(vm.battleState.killStreak)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtAmber)

            Spacer()

            Text("PARTY HP \(vm.battleState.partyHP)/\(BattleState.initialPartyHP)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(partyHPColor)

            Spacer()

            HStack(spacing: 16) {
                Button { showHistory = true } label: {
                    Text("[LOG]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.crtDimAmber)
                }
                Button { showSettings = true } label: {
                    Text("[SET]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.crtDimAmber)
                }
            }
        }
    }

    private var partyHPColor: Color {
        let fraction = Double(vm.battleState.partyHP) / Double(BattleState.initialPartyHP)
        switch fraction {
        case 0.5...: return .crtAmber
        case 0.25...: return .yellow
        default: return .crtRed
        }
    }

    private var eventGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(EventType.allCases, id: \.self) { eventType in
                EventButton(eventType: eventType) {
                    fireEvent(eventType)
                }
            }
        }
    }

    // MARK: - Actions

    private func fireEvent(_ eventType: EventType) {
        attackingType = eventType
        vm.logEvent(eventType, allRecords: records)
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
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            isPressed = true
            action()
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                isPressed = false
            }
        } label: {
            VStack(spacing: 3) {
                Text(eventType.displayName)
                    .font(.system(.subheadline, design: .monospaced).bold())
                Text(eventType.partyMember.name)
                    .font(.system(.caption2, design: .monospaced))
                    .opacity(0.7)
                Text(eventType.partyMember.role)
                    .font(.system(size: 9, design: .monospaced))
                    .opacity(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(isPressed ? .black : .crtAmber)
            .background(isPressed ? Color.crtAmber : Color.black)
            .overlay(Rectangle().stroke(Color.crtAmber, lineWidth: 1))
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}
