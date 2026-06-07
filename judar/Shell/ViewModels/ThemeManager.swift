import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "system"
    case dark   = "dark"
    case light  = "light"

    var label: String {
        switch self {
        case .system: return "システム"
        case .dark:   return "ダーク"
        case .light:  return "ライト"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark:   return .dark
        case .light:  return .light
        }
    }
}

@Observable
final class ThemeManager {
    var current: AppTheme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "judar.appTheme") }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "judar.appTheme") ?? AppTheme.system.rawValue
        current = AppTheme(rawValue: raw) ?? .system
    }
}
