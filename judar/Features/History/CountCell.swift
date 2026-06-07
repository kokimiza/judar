import SwiftUI

struct CountCell: View {
    let eventType: EventType
    let count: Int
    let isToday: Bool
    let hasUnsync: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            if count > 0 {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(eventType.accentColor.opacity(blockOpacity))
                    .padding(1.5)
            }
            if hasUnsync {
                Circle()
                    .fill(Color.rpgDanger)
                    .frame(width: 5, height: 5)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topTrailing
                    )
                    .padding(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var blockOpacity: Double {
        switch count {
        case 1: return 0.38
        case 2: return 0.60
        case 3: return 0.78
        default: return 0.92
        }
    }
}
