import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.gradientOnboarding.ignoresSafeArea()

            // Glowing orbs
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -60, y: -200)
                Circle()
                    .fill(AppTheme.accentGreen.opacity(0.10))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: 80, y: 200)
            }

            VStack(spacing: 0) {
                Spacer()

                // Logo + App Name
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(AppTheme.gradientPrimary)
                            .frame(width: 100, height: 100)
                            .shadow(color: AppTheme.accent.opacity(0.5), radius: 20, y: 8)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0)

                    VStack(spacing: 8) {
                        Text("Health Insight Pro")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Your complete health companion")
                            .font(AppFont.callout())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .opacity(isAnimating ? 1.0 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }

                Spacer()

                // Feature highlights
                VStack(spacing: 14) {
                    FeatureRow(icon: "fork.knife", color: AppTheme.accentGreen, text: "Track nutrition, macros & meal plans")
                    FeatureRow(icon: "figure.run", color: AppTheme.accentBlue, text: "Monitor activity, workouts & steps")
                    FeatureRow(icon: "moon.stars.fill", color: AppTheme.accentYellow, text: "Analyze sleep stages & recovery")
                    FeatureRow(icon: "chart.bar.fill", color: AppTheme.accentTeal, text: "Insights: Strain, Stress & Readiness")
                }
                .padding(.horizontal, 28)
                .opacity(isAnimating ? 1.0 : 0)
                .offset(y: isAnimating ? 0 : 30)

                Spacer()

                // Sign in section
                VStack(spacing: 16) {
                    // Apple Sign In Button
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let hashedNonce = authService.prepareNonce()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = hashedNonce
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let auth):
                                if let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                                    Task { await authService.signInWithApple(credential: cred) }
                                }
                            case .failure(let error):
                                print("Apple Sign In failed: \(error)")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .shadow(color: .white.opacity(0.1), radius: 8)

                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    }

                    if let err = authService.errorMessage {
                        Text(err)
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.error)
                            .multilineTextAlignment(.center)
                    }

                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(AppFont.caption())
                        .foregroundColor(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 50)
                .opacity(isAnimating ? 1.0 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    var icon: String
    var color: Color
    var text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(text)
                .font(AppFont.callout())
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
    }
}
