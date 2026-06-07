import Foundation

enum JudarError: LocalizedError {
    case userNotFound
    case invalidShareCode
    case cloudKitUnavailable
    case iCloudNotSignedIn

    var errorDescription: String? {
        switch self {
        case .userNotFound:        return "ユーザーが見つかりません"
        case .invalidShareCode:    return "共有コードが正しくありません"
        case .cloudKitUnavailable: return "iCloud に接続できません"
        case .iCloudNotSignedIn:   return "iCloud にサインインしてください"
        }
    }
}
