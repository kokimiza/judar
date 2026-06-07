import SwiftUI

struct HistoryTimeGrid: View {
    static let slotsPerDay: Int = 48
    static let rowHeight: CGFloat = 44
    static let timeColumnWidth: CGFloat = 28

    let days: [Date]
    let countIdx: [String: Int]
    let unsyncIdx: Set<String>
    let onCellTap: (GridCell) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        let currentSlot = Self.computeCurrentSlot()
                        ForEach(0..<Self.slotsPerDay, id: \.self) { slot in
                            let isHourStart = slot % 2 == 0
                            let isMajor = isHourStart && (slot / 2) % 6 == 0
                            HStack(spacing: 0) {
                                slotLabel(slot)
                                ForEach(days, id: \.self) { day in
                                    let isToday = Calendar.current
                                        .isDateInToday(day)
                                    vLine(opacity: isToday ? 0.30 : 0.15)
                                    ForEach(EventType.allCases, id: \.self) {
                                        et in
                                        CountCell(
                                            eventType: et,
                                            count: count(day, slot, et),
                                            isToday: isToday,
                                            hasUnsync: hasUnsync(day, slot, et)
                                        ) {
                                            onCellTap(
                                                GridCell(day: day, slot: slot)
                                            )
                                        }
                                        vLine(opacity: 0.06)
                                    }
                                }
                            }
                            .frame(height: Self.rowHeight)
                            // Full-width top border drawn OVER cell content —
                            // structurally prevents blocks from visually crossing
                            // the 30-minute boundary regardless of cell colors.
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(
                                        Color.rpgGold.opacity(
                                            isMajor
                                                ? 0.22
                                                : isHourStart ? 0.12 : 0.06
                                        )
                                    )
                                    .frame(height: 1)
                            }
                            .overlay {
                                if slot == currentSlot {
                                    Rectangle()
                                        .stroke(
                                            Color.rpgGold.opacity(0.55),
                                            lineWidth: 1
                                        )
                                }
                            }
                            .id(slot)
                        }
                    } header: {
                        columnHeader
                    }
                }
            }
            .onAppear {
                proxy.scrollTo(
                    max(0, Self.computeCurrentSlot() - 4),
                    anchor: .top
                )
            }
        }
    }

    // MARK: - Pinned column header

    private var columnHeader: some View {
        VStack(spacing: 0) {
            // Date labels row
            HStack(spacing: 0) {
                Spacer().frame(width: Self.timeColumnWidth)
                ForEach(days, id: \.self) { day in
                    let isToday = Calendar.current.isDateInToday(day)
                    vLine(opacity: isToday ? 0.3 : 0.15)
                    HStack(spacing: 0) {
                        ForEach(EventType.allCases, id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                            vLine(opacity: 0)
                        }
                    }
                    .background(
                        isToday ? Color.crtAmber.opacity(0.07) : Color.clear
                    )
                    .overlay {
                        Text(dayLabel(day))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(isToday ? .crtAmber : .crtDimAmber)
                    }
                }
            }
            .frame(height: 14)

            Rectangle().fill(Color.crtAmber.opacity(0.08)).frame(height: 1)

            // Event type icons row — same HStack structure as grid rows
            HStack(spacing: 0) {
                Spacer().frame(width: Self.timeColumnWidth)
                ForEach(days, id: \.self) { day in
                    let isToday = Calendar.current.isDateInToday(day)
                    vLine(opacity: isToday ? 0.3 : 0.15)
                    ForEach(EventType.allCases, id: \.self) { et in
                        Image(systemName: et.icon)
                            .font(.system(size: 9))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        vLine(opacity: 0.06)
                    }
                }
            }
            .frame(height: 16)

            Rectangle().fill(Color.crtAmber.opacity(0.2)).frame(height: 1)
        }
        .background(Color.rpgBackground)
    }

    // MARK: - Time axis label

    private func slotLabel(_ slot: Int) -> some View {
        let isHourStart = slot % 2 == 0
        let hour = slot / 2
        return ZStack(alignment: .topLeading) {
            if isHourStart {
                Text(String(format: "%02d", hour))
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.rpgGoldDim)
                    .offset(x: 3, y: 2)
            }
        }
        .frame(width: Self.timeColumnWidth)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func key(_ day: Date, _ slot: Int, _ type: EventType) -> String {
        // days are already start-of-day values passed from HistoryView
        "\(day.timeIntervalSince1970)_\(slot)_\(type.rawValue)"
    }

    private func count(_ day: Date, _ slot: Int, _ type: EventType) -> Int {
        countIdx[key(day, slot, type)] ?? 0
    }

    private func hasUnsync(_ day: Date, _ slot: Int, _ type: EventType) -> Bool
    {
        unsyncIdx.contains(key(day, slot, type))
    }

    // m < 30 → first half of the hour (前半), m >= 30 → second half (後半)
    static func computeCurrentSlot() -> Int {
        let cal = Calendar.current
        let h = cal.component(.hour, from: .now)
        let m = cal.component(.minute, from: .now)
        return h * 2 + (m >= 30 ? 1 : 0)
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        let wday = cal.component(.weekday, from: date) - 1
        let weekday = ["日", "月", "火", "水", "木", "金", "土"][wday]
        return "\(m)/\(d)(\(weekday))"
    }

    private func vLine(opacity: Double) -> some View {
        Rectangle().fill(Color.rpgGold.opacity(opacity)).frame(width: 1)
    }
}
