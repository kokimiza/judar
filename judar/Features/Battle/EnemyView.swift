import SwiftUI

struct EnemyView: View {
    let enemy: Enemy
    let level: Int
    var isFlashing: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            nameRow
            hpBar
            asciiArt
            attributeRow
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.rpgSurface.opacity(0.7))
        .overlay(Rectangle().stroke(Color.rpgBorder.opacity(0.55), lineWidth: 1))
    }

    // MARK: - Name

    private var nameRow: some View {
        HStack(spacing: 8) {
            Text("Lv.\(level)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.rpgGoldDim)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .overlay(
                    Rectangle().stroke(Color.rpgBorder.opacity(0.5), lineWidth: 1)
                )
            Text(enemy.template.name)
                .font(.system(.title2, design: .monospaced).bold())
                .foregroundColor(.rpgDanger)
        }
    }

    // MARK: - HP bar (20-char block visual)

    private var hpBar: some View {
        let total = 20
        let filled = max(0, Int(enemy.hpFraction * Double(total)))
        let bar =
            String(repeating: "█", count: filled)
            + String(repeating: "░", count: total - filled)
        return VStack(spacing: 2) {
            Text("[\(bar)]")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(hpColor)
            Text("\(enemy.currentHP) / \(enemy.template.maxHP)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(hpColor.opacity(0.65))
        }
    }

    private var hpColor: Color {
        switch enemy.hpFraction {
        case 0.5...: return .rpgHealthy
        case 0.25...: return .yellow
        default: return .rpgDanger
        }
    }

    // MARK: - ASCII art

    private var asciiArt: some View {
        Text(enemy.template.asciiArt)
            .font(.system(size: 15, design: .monospaced))
            .foregroundColor(.rpgGold)
            .multilineTextAlignment(.center)
            .opacity(isFlashing ? 0.15 : 1.0)
            .animation(
                .easeOut(duration: 0.08).repeatCount(3, autoreverses: true),
                value: isFlashing
            )
    }

    // MARK: - Weakness + resistance

    private var attributeRow: some View {
        HStack(spacing: 10) {
            if !enemy.template.weaknesses.isEmpty {
                let label = enemy.template.weaknesses
                    .map { "[\($0.shortLabel)]" }.joined()
                Text("弱:\(label)")
                    .foregroundColor(.rpgGold)
            }
            if !enemy.template.resistances.isEmpty {
                let label = enemy.template.resistances
                    .map { "[\($0.shortLabel)]" }.joined()
                Text("耐:\(label)")
                    .foregroundColor(.rpgGoldDim)
            }
            if enemy.template.weaknesses.isEmpty
                && enemy.template.resistances.isEmpty
            {
                Text("[耐性なし]")
                    .foregroundColor(.rpgGoldDim)
            }
        }
        .font(.system(.caption2, design: .monospaced))
    }
}

extension AttackType {
    fileprivate var shortLabel: String {
        switch self {
        case .physical: return "物理"
        case .magical: return "魔法"
        case .heal: return "回復"
        }
    }
}
