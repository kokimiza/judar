import SwiftUI

struct BattleLogView: View {
    let lines: [String]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) {
                        index,
                        line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.rpgGold)
                            .id(index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            }
            .onChange(of: lines.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(lines.count - 1, anchor: .bottom)
                }
            }
        }
        .frame(height: 70)
        .background(Color.rpgSurface.opacity(0.5))
        .overlay(
            Rectangle()
                .stroke(Color.rpgBorder.opacity(0.35), lineWidth: 1)
        )
    }
}
