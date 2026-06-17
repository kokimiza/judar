import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        ZStack {
            Color.rpgBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Title block
                VStack(spacing: 8) {
                    Text("R メモ")
                        .font(.system(size: 48, design: .monospaced).bold())
                        .foregroundColor(.crtAmber)
                    Text("赤ちゃん育児記録 RPG")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.crtDimAmber)
                }

                // ASCII art decoration
                Text("  ┌─────────────┐\n  │ *** START ***│\n  └─────────────┘")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.crtDimAmber)
                    .multilineTextAlignment(.center)

                Spacer()

                VStack(spacing: 12) {
                    Text("> Apple ID でログイン")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.crtDimAmber)

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = []
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            guard
                                let cred = authorization.credential
                                    as? ASAuthorizationAppleIDCredential
                            else { return }
                            authService.handleSignIn(userId: cred.user)
                        case .failure(let error):
                            // User cancelled or error — stay on sign-in screen
                            _ = error
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(width: 280, height: 44)
                    .cornerRadius(0)

                    if let err = authService.lastError {
                        Text(err.localizedDescription)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.crtRed)
                    }

                    // Guest mode: local-only, no CloudKit sync
                    Button {
                        authService.continueAsGuest()
                    } label: {
                        Text("[ ゲストとして続ける ]")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.crtDimAmber)
                            .frame(width: 280)
                            .padding(.vertical, 10)
                            .overlay(
                                Rectangle().stroke(
                                    Color.crtDimAmber,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)

                    Text("ゲストモードではデータ共有・バックアップは利用できません")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color.crtDimAmber.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(width: 280)
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
    }
}
