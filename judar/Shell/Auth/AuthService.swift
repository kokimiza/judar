import AuthenticationServices
import Foundation

@Observable
@MainActor
final class AuthService {
    // true when signed in with Apple ID
    private(set) var isAuthenticated = false
    // true when user chose to skip sign-in (local-only mode)
    private(set) var isGuest = false
    var lastError: Error?

    // Either condition allows the app to boot
    var canProceed: Bool { isAuthenticated || isGuest }

    private let userIdKey = "appleSignInUserId"
    private let guestKey = "guestModeActive"

    init() {
        // Restore guest flag across launches so guest users aren't re-prompted
        isGuest = UserDefaults.standard.bool(forKey: guestKey)
    }

    // MARK: - Apple Sign In

    func checkStoredAuth() async -> Bool {
        guard let storedId = UserDefaults.standard.string(forKey: userIdKey)
        else {
            return false
        }
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: storedId)
            if state == .authorized {
                isAuthenticated = true
                return true
            } else {
                clearAuth()
                return false
            }
        } catch {
            // credential state check failed (offline or transient error).
            // NOTE: CloudKit record deletion does NOT revoke this credential —
            // only removing the app in iOS Settings > Apple ID > Apps revokes it.
            // Trust the stored Apple ID so the app works offline.
            isAuthenticated = true
            return true
        }
    }

    func handleSignIn(userId: String) {
        // Upgrade from guest to signed-in if needed
        UserDefaults.standard.set(userId, forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: guestKey)
        isGuest = false
        isAuthenticated = true
    }

    // MARK: - Guest mode

    // Allows the user to use all local features without an Apple ID.
    // CloudKit sync and family sharing are silently skipped.
    func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: guestKey)
        isGuest = true
    }

    // MARK: - Sign out

    func clearAuth() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: guestKey)
        isAuthenticated = false
        isGuest = false
    }
}
