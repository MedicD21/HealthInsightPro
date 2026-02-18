import Foundation
import AuthenticationServices
import Supabase
import CryptoKit

// MARK: - Auth Service
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared.client
    private var currentNonce: String?
    private let debugBypassUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private init() {
        Task { await checkSession() }
    }

    // MARK: - Session Check
    func checkSession() async {
        if AppEnvironment.bypassAppleSignIn {
            applyDebugBypassSession()
            return
        }

        do {
            let session = try await supabase.auth.session
            isAuthenticated = true
            await loadUserProfile(userId: session.user.id)
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    func signInForTesting() {
        guard AppEnvironment.isTesting else { return }
        applyDebugBypassSession()
    }

    // MARK: - Apple Sign In
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil

        guard
            let identityToken = credential.identityToken,
            let tokenString = String(data: identityToken, encoding: .utf8),
            let nonce = currentNonce
        else {
            errorMessage = "Failed to get Apple ID token."
            isLoading = false
            return
        }

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: tokenString, nonce: nonce)
            )

            // Build display name from Apple credential
            let fullName: String?
            if let given = credential.fullName?.givenName, let family = credential.fullName?.familyName {
                fullName = "\(given) \(family)"
            } else {
                fullName = credential.fullName?.givenName
            }

            let email = credential.email ?? session.user.email

            // Check if profile exists
            if let existing = try? await SupabaseService.shared.fetchProfile(userId: session.user.id) {
                currentUser = existing
                isAuthenticated = true
            } else {
                // New user — create a stub profile (onboarding will fill the rest)
                let newProfile = UserProfile(
                    id: session.user.id,
                    appleUserId: credential.user,
                    email: email,
                    fullName: fullName
                )
                try await SupabaseService.shared.saveProfile(newProfile)
                currentUser = newProfile
                isAuthenticated = true
            }
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Nonce (PKCE / replay protection)
    func prepareNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Load Profile
    func loadUserProfile(userId: UUID) async {
        do {
            currentUser = try await SupabaseService.shared.fetchProfile(userId: userId)
        } catch {
            print("Failed to load user profile: \(error)")
        }
    }

    // MARK: - Update Profile
    func updateProfile(_ profile: UserProfile) async throws {
        try await SupabaseService.shared.updateProfile(profile)
        currentUser = profile
    }

    // MARK: - Sign Out
    func signOut() async {
        if AppEnvironment.bypassAppleSignIn {
            isAuthenticated = false
            currentUser = nil
            onboardingComplete = false
            errorMessage = nil
            return
        }

        do {
            try await supabase.auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Onboarding complete flag
    var onboardingComplete: Bool {
        get { UserDefaults.standard.bool(forKey: Constants.Keys.onboardingComplete) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.Keys.onboardingComplete) }
    }

    private func applyDebugBypassSession() {
        guard AppEnvironment.isTesting else { return }

        currentUser = UserProfile(
            id: debugBypassUserID,
            appleUserId: "simulator-debug-user",
            email: "simulator@healthinsightpro.local",
            fullName: "Simulator Test User"
        )
        isAuthenticated = true
        onboardingComplete = true
        errorMessage = nil
        isLoading = false
    }
}
