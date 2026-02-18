import SwiftUI

@main
struct HealthInsightProApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authService)
                .preferredColorScheme(.dark)
                .overlay(alignment: .topTrailing) {
                    if AppEnvironment.isTesting {
                        Text(AppEnvironment.modeLabel)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.9))
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                            .padding(.top, 10)
                            .padding(.trailing, 10)
                    }
                }
        }
    }
}

// MARK: - Root View (routes to Sign In / Onboarding / Main)
struct AppRootView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if !authService.isAuthenticated {
                // Step 1: Sign in
                SignInView()
                    .environmentObject(authService)
            } else if !authService.onboardingComplete, let profile = authService.currentUser {
                // Step 2: Onboarding
                OnboardingView(currentUser: profile)
                    .environmentObject(authService)
            } else {
                // Step 3: Main app
                DashboardView()
                    .environmentObject(authService)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: authService.onboardingComplete)
    }
}
