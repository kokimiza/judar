import SwiftUI

struct BattleLogView: View {
    let lines: [String]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.crtAmber)
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
        .frame(height: 88)
        .overlay(
            Rectangle()
                .stroke(Color.crtAmber.opacity(0.35), lineWidth: 1)
        )
    }
}
