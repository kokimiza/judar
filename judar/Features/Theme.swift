import SwiftUI

// MARK: - FF4-inspired adaptive color palette

extension Color {

    // Backgrounds
    static let rpgBackground = Color(
        uiColor: .init(dynamicProvider: { t in
            t.userInterfaceStyle == .dark
                ? .init(red: 0.055, green: 0.098, blue: 0.200, alpha: 1)  // #0E1933 deep navy
                : .init(red: 0.945, green: 0.925, blue: 0.859, alpha: 1)  // #F1ECDB parchment
        })
    )

    static let rpgSurface = Color(
        uiColor: .init(dynamicProvider: { t in
            t.userInterfaceStyle == .dark
                ? .init(red: 0.090, green: 0.137, blue: 0.267, alpha: 1)  // #172344 panel
                : .init(red: 0.906, green: 0.882, blue: 0.800, alpha: 1)  // #E7E1CC card
        })
    )

    // Primary text — warm gold
    static let rpgGold = Color(
        uiColor: .init(dynamicProvider: { t in
            t.userInterfaceStyle == .dark
                ? .init(red: 0.949, green: 0.847, blue: 0.510, alpha: 1)  // #F2D882
                : .init(red: 0.294, green: 0.200, blue: 0.039, alpha: 1)  // #4B330A
        })
    )

    // Muted / secondary text
    static let rpgGoldDim = Color(
        uiColor: .init(dynamicProvider: { t in
            t.userInterfaceStyle == .dark
                ? .init(red: 0.573, green: 0.486, blue: 0.282, alpha: 1)  // #927C48
                : .init(red: 0.478, green: 0.376, blue: 0.188, alpha: 1)  // #7A6030
        })
    )

    // Border — blue in dark (FF4 menu), bronze in light
    static let rpgBorder = Color(
        uiColor: .init(dynamicProvider: { t in
            t.userInterfaceStyle == .dark
                ? .init(red: 0.227, green: 0.373, blue: 0.800, alpha: 1)  // #3A5FCC
                : .init(red: 0.608, green: 0.478, blue: 0.188, alpha: 1)  // #9B7A30
        })
    )

    // HP healthy
    static let rpgHealthy = Color(
        uiColor: .init(dynamicProvider: { t in
            t.userInterfaceStyle == .dark
                ? .init(red: 0.314, green: 0.878, blue: 0.502, alpha: 1)  // #50E080
                : .init(red: 0.165, green: 0.471, blue: 0.251, alpha: 1)  // #2A7840
        })
    )

    // Danger / low HP / error
    static let rpgDanger = Color(
        uiColor: .init(dynamicProvider: { t in
            t.userInterfaceStyle == .dark
                ? .init(red: 0.878, green: 0.188, blue: 0.188, alpha: 1)  // #E03030
                : .init(red: 0.690, green: 0.125, blue: 0.125, alpha: 1)  // #B02020
        })
    )

    // Legacy aliases — existing views stay correct while gaining FF4 colors
    static var crtAmber: Color { .rpgGold }
    static var crtDimAmber: Color { .rpgGoldDim }
    static var crtRed: Color { .rpgDanger }
}

// MARK: - EventType accent colors (vibrant, legible on both backgrounds)

extension EventType {
    var accentColor: Color {
        switch self {
        case .diaper: return Color(red: 0.95, green: 0.73, blue: 0.12)  // rich gold
        case .breastfeed: return Color(red: 0.95, green: 0.38, blue: 0.58)  // vivid rose
        case .formula: return Color(red: 0.72, green: 0.70, blue: 0.88)  // soft lavender
        case .pumpedMilk: return Color(red: 0.85, green: 0.55, blue: 0.78)  // warm mauve
        }
    }
}
