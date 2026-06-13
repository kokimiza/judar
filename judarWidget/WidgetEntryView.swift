import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    let entry: JudarWidgetEntry
    @Environment(\.widgetFamily) private var family

    // Mirror of Theme.swift — widget cannot import the main app module
    private var rpgBackground: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.055, green: 0.098, blue: 0.200, alpha: 1)
                : UIColor(red: 0.945, green: 0.925, blue: 0.859, alpha: 1)
        })
    }
    private var rpgGold: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.949, green: 0.847, blue: 0.510, alpha: 1)
                : UIColor(red: 0.294, green: 0.200, blue: 0.039, alpha: 1)
        })
    }
    private var rpgGoldDim: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.573, green: 0.486, blue: 0.282, alpha: 1)
                : UIColor(red: 0.478, green: 0.376, blue: 0.188, alpha: 1)
        })
    }
    private var rpgBorder: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.227, green: 0.373, blue: 0.800, alpha: 1)
                : UIColor(red: 0.608, green: 0.478, blue: 0.188, alpha: 1)
        })
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium: mediumLayout
            default:            smallLayout
            }
        }
        .containerBackground(rpgBackground, for: .widget)
    }

    // MARK: - Small: 2×2 grid

    private var smallLayout: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                countCell(.diaper)
                Rectangle().fill(rpgBorder.opacity(0.35)).frame(width: 1)
                countCell(.breastfeed)
            }
            GridRow {
                Rectangle().fill(rpgBorder.opacity(0.35)).gridCellColumns(3).frame(height: 1)
            }
            GridRow {
                countCell(.formula)
                Rectangle().fill(rpgBorder.opacity(0.35)).frame(width: 1)
                countCell(.pumpedMilk)
            }
        }
        .padding(10)
    }

    // MARK: - Medium: 4 equal columns

    private var mediumLayout: some View {
        HStack(spacing: 0) {
            ForEach(WEventType.allCases, id: \.rawValue) { et in
                mediumCountCell(et)
                if et != WEventType.allCases.last {
                    Rectangle().fill(rpgBorder.opacity(0.35)).frame(width: 1)
                }
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Cells

    private func countCell(_ et: WEventType) -> some View {
        VStack(spacing: 3) {
            Text(et.icon)
                .font(.system(size: 18))
            timeAgoText(for: entry.counts[lastDate: et], size: 11)
            Text("\(entry.counts[et])")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(rpgGoldDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func mediumCountCell(_ et: WEventType) -> some View {
        VStack(spacing: 4) {
            Text(et.icon)
                .font(.system(size: 22))
            timeAgoText(for: entry.counts[lastDate: et], size: 13)
            Text("\(entry.counts[et])")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(rpgGoldDim)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Time-ago label (分単位・静的)

    @ViewBuilder
    private func timeAgoText(for date: Date?, size: CGFloat) -> some View {
        let label = date.flatMap { isRecentEnough($0) ? minuteAgoLabel($0) : nil }
        if let label {
            Text(label)
                .font(.system(size: size, weight: .semibold, design: .monospaced))
                .foregroundStyle(rpgGold)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
        } else {
            Text("---")
                .font(.system(size: size, weight: .semibold, design: .monospaced))
                .foregroundStyle(rpgGoldDim.opacity(0.5))
        }
    }

    private func minuteAgoLabel(_ date: Date) -> String {
        let minutes = Int(entry.date.timeIntervalSince(date) / 60)
        if minutes < 1  { return "1分未満" }
        if minutes < 60 { return "\(minutes)分前" }
        return "\(minutes / 60)時間前"
    }

    private func isRecentEnough(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.isDateInToday(date) || cal.isDateInYesterday(date)
    }
}
