import Charts
import SwiftUI

// MARK: - HistoryAmountChart

struct HistoryAmountChart: View {
    let data: [DailyAmount]

    private static let types: [EventType] = [.formula, .pumpedMilk]

    private static let colorScale: [String: Color] = [
        EventType.formula.displayName: .rpgGold,
        EventType.pumpedMilk.displayName: .rpgGoldDim,
    ]

    private var hasAnyAmount: Bool {
        data.contains { $0.totalMl > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            legend

            if hasAnyAmount {
                chart
            } else {
                emptyState
            }

            totalsSummary
        }
        .padding(16)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(data) { item in
            BarMark(
                x: .value("日付", item.day, unit: .day),
                y: .value("ml", item.totalMl)
            )
            .foregroundStyle(by: .value("種類", item.eventType.displayName))
            .position(by: .value("種類", item.eventType.displayName))
            .cornerRadius(2)
        }
        .chartForegroundStyleScale(
            domain: Self.types.map(\.displayName),
            range: Self.types.map { Self.colorScale[$0.displayName] ?? .rpgGold }
        )
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine().foregroundStyle(Color.rpgBorder.opacity(0.3))
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.rpgGoldDim)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Color.rpgBorder.opacity(0.2))
                AxisValueLabel()
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.rpgGoldDim)
            }
        }
        .frame(height: 220)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            ForEach(Self.types, id: \.self) { type in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Self.colorScale[type.displayName] ?? .rpgGold)
                        .frame(width: 8, height: 8)
                    Text(type.displayName)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.rpgGoldDim)
                }
            }
            Spacer()
        }
    }

    // MARK: - Totals summary

    private var totalsSummary: some View {
        HStack(spacing: 0) {
            ForEach(Self.types, id: \.self) { type in
                let total = data
                    .filter { $0.eventType == type }
                    .reduce(0) { $0 + $1.totalMl }
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.rpgGoldDim)
                    Text("\(total) ml")
                        .font(.system(.title3, design: .monospaced).bold())
                        .foregroundColor(.rpgGold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar")
                .font(.system(size: 28))
                .foregroundColor(.rpgGoldDim.opacity(0.5))
            Text("> この期間の記録はありません")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.rpgGoldDim.opacity(0.7))
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
}
