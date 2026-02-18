import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showEditProfile = false
    @State private var showSignOutAlert = false

    var profile: UserProfile? { authService.currentUser }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile header
                        ProfileHeader(profile: profile) { showEditProfile = true }

                        // Stats summary
                        ProfileStatsSummary(profile: profile)

                        // Goals section
                        if let profile = profile {
                            GoalsSection(profile: profile)
                        }

                        // Settings sections
                        SettingsSection(title: "Health Data") {
                            SettingsRow(icon: "heart.fill", color: AppTheme.accentPink, title: "Apple Health")
                            SettingsRow(icon: "applewatch", color: AppTheme.accent, title: "Apple Watch")
                            SettingsRow(icon: "antenna.radiowaves.left.and.right", color: AppTheme.accentBlue, title: "Garmin Connect")
                        }

                        SettingsSection(title: "Preferences") {
                            SettingsRow(icon: "ruler.fill", color: AppTheme.accentGreen, title: "Units (kg / cm)")
                            SettingsRow(icon: "bell.fill", color: AppTheme.accentOrange, title: "Notifications")
                            SettingsRow(icon: "moon.fill", color: AppTheme.accentYellow, title: "Appearance")
                        }

                        SettingsSection(title: "Account") {
                            SettingsRow(icon: "person.crop.circle", color: AppTheme.accent, title: "Edit Profile") {
                                showEditProfile = true
                            }
                            SettingsRow(icon: "shield.lefthalf.filled", color: AppTheme.accentTeal, title: "Privacy Policy")
                            SettingsRow(icon: "doc.text.fill", color: AppTheme.textSecondary, title: "Terms of Service")
                            SettingsRow(icon: "arrow.right.circle.fill", color: AppTheme.error, title: "Sign Out") {
                                showSignOutAlert = true
                            }
                        }

                        // Version
                        Text("Health Insight Pro v\(Constants.App.version)")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(authService: authService)
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    Task { await authService.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Header
struct ProfileHeader: View {
    var profile: UserProfile?
    var onEdit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.gradientPrimary)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 16)
                Text(String(profile?.fullName?.prefix(1) ?? "H"))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 6) {
                Text(profile?.fullName ?? "Health Insight User")
                    .font(AppFont.title2(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                if let email = profile?.email {
                    Text(email)
                        .font(AppFont.subheadline())
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Button(action: onEdit) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .font(AppFont.subheadline(.semibold))
                .foregroundColor(AppTheme.accent)
                .padding(.horizontal, 20).padding(.vertical, 8)
                .background(AppTheme.accent.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}

// MARK: - Stats Summary
struct ProfileStatsSummary: View {
    var profile: UserProfile?

    var body: some View {
        HStack(spacing: 0) {
            StatPill(label: "BMI", value: profile.map { String(format: "%.1f", $0.bmi) } ?? "--",
                     subtitle: profile?.bmiCategory ?? "")
            Divider().background(AppTheme.borderSubtle).frame(height: 44)
            StatPill(label: "Age", value: profile?.age.map { "\($0)" } ?? "--", subtitle: "years")
            Divider().background(AppTheme.borderSubtle).frame(height: 44)
            StatPill(label: "Height", value: profile.map { "\(Int($0.heightCm))" } ?? "--", subtitle: "cm")
            Divider().background(AppTheme.borderSubtle).frame(height: 44)
            StatPill(label: "Weight", value: profile.map { String(format: "%.1f", $0.weightKg) } ?? "--", subtitle: "kg")
        }
        .padding(.vertical, 16)
        .cardStyle()
    }
}

struct StatPill: View {
    var label: String; var value: String; var subtitle: String

    var body: some View {
        VStack(spacing: 3) {
            Text(label).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
            Text(value).font(AppFont.title3(.bold)).foregroundColor(AppTheme.textPrimary)
            Text(subtitle).font(AppFont.caption()).foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Goals Section
struct GoalsSection: View {
    var profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Goals").font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                GoalItem(icon: "flame.fill", color: AppTheme.accentOrange,
                         label: "Calories", value: "\(Int(profile.dailyCalorieGoal)) kcal")
                GoalItem(icon: "figure.walk", color: AppTheme.accentBlue,
                         label: "Steps", value: "\(profile.dailyStepGoal)")
                GoalItem(icon: "drop.fill", color: AppTheme.accentTeal,
                         label: "Water", value: "\(Int(profile.dailyWaterGoal)) ml")
                GoalItem(icon: "moon.stars.fill", color: AppTheme.accentYellow,
                         label: "Sleep", value: "\(profile.nightlySleepGoal)h")
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

struct GoalItem: View {
    var icon: String; var color: Color; var label: String; var value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
                Text(value).font(AppFont.subheadline(.bold)).foregroundColor(AppTheme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(AppFont.caption(.semibold))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content
            }
            .cardStyle()
        }
    }
}

struct SettingsRow: View {
    var icon: String
    var color: Color
    var title: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(AppFont.body())
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, Constants.Layout.padding)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var fullName: String = ""
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var calorieGoal: Double = 2000
    @State private var waterGoal: Double = 2500
    @State private var stepGoal: Double = 10000
    @State private var sleepGoal: Double = 8.0

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Name
                        ProfileTextField(label: "Full Name", placeholder: "Your name", text: $fullName)

                        // Height & weight
                        HStack(spacing: 12) {
                            OnboardingSliderRow(title: "Height (cm)", value: $heightCm, range: 130...220, unit: "cm", format: "%.0f")
                        }
                        OnboardingSliderRow(title: "Weight (kg)", value: $weightKg, range: 30...250, unit: "kg", format: "%.1f")

                        // Goals
                        OnboardingSliderRow(title: "Calorie Goal", value: $calorieGoal, range: 1000...5000, unit: "kcal", format: "%.0f")
                        OnboardingSliderRow(title: "Water Goal", value: $waterGoal, range: 500...5000, unit: "ml", format: "%.0f")
                        OnboardingSliderRow(title: "Step Goal", value: $stepGoal, range: 1000...30000, unit: "steps", format: "%.0f")
                        OnboardingSliderRow(title: "Sleep Goal", value: $sleepGoal, range: 4...12, unit: "h", format: "%.1f")

                        Button {
                            Task { await saveChanges() }
                        } label: {
                            Text("Save Changes").font(AppFont.headline()).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 56)
                                .background(AppTheme.gradientPrimary).cornerRadius(16)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(AppTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { loadCurrent() }
    }

    func loadCurrent() {
        guard let p = authService.currentUser else { return }
        fullName = p.fullName ?? ""
        heightCm = p.heightCm
        weightKg = p.weightKg
        activityLevel = p.activityLevel
        calorieGoal = p.dailyCalorieGoal
        waterGoal = p.dailyWaterGoal
        stepGoal = Double(p.dailyStepGoal)
        sleepGoal = p.nightlySleepGoal
    }

    func saveChanges() async {
        guard var profile = authService.currentUser else { return }
        profile.fullName = fullName
        profile.heightCm = heightCm
        profile.weightKg = weightKg
        profile.activityLevel = activityLevel
        profile.dailyCalorieGoal = calorieGoal
        profile.dailyWaterGoal = waterGoal
        profile.dailyStepGoal = Int(stepGoal)
        profile.nightlySleepGoal = sleepGoal
        profile.updatedAt = Date()
        try? await authService.updateProfile(profile)
        dismiss()
    }
}

struct ProfileTextField: View {
    var label: String; var placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textSecondary)
            TextField(placeholder, text: $text)
                .foregroundColor(AppTheme.textPrimary)
                .font(AppFont.body())
                .padding(14)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderSubtle, lineWidth: 1))
        }
    }
}
