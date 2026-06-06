import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    let entry: JudarWidgetEntry
    @Environment(\.widgetFamily) private var family

    private let amber    = Color(red: 1.0, green: 0.71, blue: 0.0)
    private let dimAmber = Color(red: 1.0, green: 0.71, blue: 0.0).opacity(0.5)

    var body: some View {
        switch family {
        case .systemMedium: mediumLayout
        default:            smallLayout
        }
    }

    // MARK: - Layouts

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("judar")
                .font(.system(.caption2, design: .monospaced).bold())
                .foregroundColor(dimAmber)
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
                GridRow {
                    countCell(.poop,       entry.counts.poop)
                    countCell(.pee,        entry.counts.pee)
                }
                GridRow {
                    countCell(.breastfeed, entry.counts.breastfeed)
                    countCell(.formula,    entry.counts.formula)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.black)
    }

    private var mediumLayout: some View {
        HStack(spacing: 16) {
            ForEach(WEventType.allCases, id: \.rawValue) { et in
                countCell(et, entry.counts[et])
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private func countCell(_ et: WEventType, _ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(et.displayName)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(dimAmber)
            Text("\(count)")
                .font(.system(.title2, design: .monospaced).bold())
                .foregroundColor(amber)
        }
    }
}
