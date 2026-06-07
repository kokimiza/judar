import SwiftUI

struct EnemyView: View {
    let enemy: Enemy
    let level: Int
    var isFlashing: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            // Level + name row
            HStack(spacing: 6) {
                Text("Lv.\(level)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.crtDimAmber)
                Text(enemy.template.name)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(.crtRed)
            }

            hpBar

            Text(enemy.template.asciiArt)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.crtAmber)
                .multilineTextAlignment(.center)
                .opacity(isFlashing ? 0.2 : 1.0)
                .animation(.easeOut(duration: 0.08).repeatCount(3, autoreverses: true), value: isFlashing)

            resistanceLabel
        }
        .padding(.vertical, 8)
    }

    private var hpBar: some View {
        let filled = Int(enemy.hpFraction * 10)
        let empty  = 10 - filled
        let bar    = String(repeating: "#", count: filled) + String(repeating: "-", count: empty)
        return Text("HP [\(bar)] \(enemy.currentHP)/\(enemy.template.maxHP)")
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(hpColor)
    }

    private var hpColor: Color {
        switch enemy.hpFraction {
        case 0.5...: return .crtAmber
        case 0.25...: return .yellow
        default: return .crtRed
        }
    }

    private var resistanceLabel: some View {
        let tags = enemy.template.resistances.map { "[\($0.shortLabel)]" }.joined(separator: " ")
        return Group {
            if tags.isEmpty {
                Text("[耐性なし]")
            } else {
                Text("耐性: \(tags)")
            }
        }
        .font(.system(.caption2, design: .monospaced))
        .foregroundColor(.crtDimAmber)
    }
}

private extension AttackType {
    var shortLabel: String {
        switch self {
        case .physical: return "物理"
        case .magical:  return "魔法"
        case .heal:     return "回復"
        }
    }
}
