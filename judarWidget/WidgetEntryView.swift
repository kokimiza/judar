import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    let entry: JudarWidgetEntry
    @Environment(\.widgetFamily) private var family

    private let amber    = Color(red: 1.0, green: 0.71, blue: 0.0)
    private let dimAmber = Color(red: 1.0, green: 0.71, blue: 0.0).opacity(0.45)

    var body: some View {
        Group {
            switch family {
            case .systemMedium: mediumLayout
            default:            smallLayout
            }
        }
        .containerBackground(Color.black, for: .widget)
    }

    // MARK: - Small (systemSmall) ─ 2×2 grid + last-action footer

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("judar")
                    .font(.system(.caption2, design: .monospaced).bold())
                    .foregroundStyle(amber)
                Spacer()
                Text("TODAY")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(dimAmber)
            }

            Divider().overlay(dimAmber).padding(.vertical, 4)

            // 2×2 count grid
            Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 6) {
                GridRow {
                    countCell(.poop)
                    countCell(.pee)
                }
                GridRow {
                    countCell(.breastfeed)
                    countCell(.formula)
                }
            }

            Spacer(minLength: 0)

            Divider().overlay(dimAmber).padding(.vertical, 4)

            // Last-action footer
            lastActionLine
        }
        .padding(10)
    }

    // MARK: - Medium (systemMedium) ─ 4 columns + last-action header

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header bar
            HStack {
                Text("judar")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundStyle(amber)
                Spacer()
                lastActionLine
            }

            Divider().overlay(dimAmber)

            // 4 columns
            HStack(spacing: 0) {
                ForEach(WEventType.allCases, id: \.rawValue) { et in
                    mediumCountCell(et)
                    if et != WEventType.allCases.last {
                        Divider()
                            .overlay(dimAmber.opacity(0.3))
                            .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(12)
    }

    // MARK: - Cells

    // Small-widget cell: label top, count bottom
    private func countCell(_ et: WEventType) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(et.displayName)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(dimAmber)
            Text("\(entry.counts[et])")
                .font(.system(.title, design: .monospaced).bold())
                .foregroundStyle(amber)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Medium-widget cell: character name, count, event label
    private func mediumCountCell(_ et: WEventType) -> some View {
        VStack(spacing: 3) {
            Text(et.memberName)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(dimAmber)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(entry.counts[et])")
                .font(.system(.title, design: .monospaced).bold())
                .foregroundStyle(amber)
            Text(et.displayName)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(dimAmber)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Last-action line

    @ViewBuilder
    private var lastActionLine: some View {
        if let last = entry.counts.lastActionDate {
            HStack(spacing: 3) {
                Text(">")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(dimAmber)
                // Text(date:style:.relative) auto-updates without timeline reload
                Text(last, style: .relative)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(dimAmber)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        } else {
            Text("> ---")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(dimAmber)
        }
    }
}
