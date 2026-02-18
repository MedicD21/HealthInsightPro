import SwiftUI

// MARK: - Onboarding Container
struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var step: Int = 0
    @State private var profile: UserProfile

    // Onboarding state
    @State private var goals: Set<HealthGoal> = [.generalHealth]
    @State private var biologicalSex: BiologicalSex = .other
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var heightInches: Double = ImperialUnits.cmToInches(170)
    @State private var weightLbs: Double = ImperialUnits.kgToLbs(70)
    @State private var targetWeightLbs: Double = ImperialUnits.kgToLbs(65)
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var isCompleting = false
    @State private var healthKitGranted = false

    init(currentUser: UserProfile) {
        _profile = State(initialValue: currentUser)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                OnboardingProgressBar(current: step, total: Constants.Onboarding.totalSteps)
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                // Page content
                TabView(selection: $step) {
                    OnboardingWelcomePage(step: $step).tag(0)
                    OnboardingGoalsPage(goals: $goals, step: $step).tag(1)
                    OnboardingBodyMetricsPage(sex: $biologicalSex, dob: $dateOfBirth,
                                              heightInches: $heightInches, weightLbs: $weightLbs, step: $step).tag(2)
                    OnboardingTargetPage(targetWeightLbs: $targetWeightLbs,
                                         currentWeightLbs: weightLbs, step: $step).tag(3)
                    OnboardingActivityPage(activityLevel: $activityLevel, step: $step).tag(4)
                    OnboardingPermissionsPage(healthKitGranted: $healthKitGranted, step: $step,
                                             onComplete: finishOnboarding).tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: step)
            }
        }
    }

    func finishOnboarding() {
        isCompleting = true
        guard var updated = authService.currentUser else { return }

        updated.biologicalSex = biologicalSex
        updated.dateOfBirth = dateOfBirth
        updated.heightCm = ImperialUnits.inchesToCm(heightInches)
        updated.weightKg = ImperialUnits.lbsToKg(weightLbs)
        updated.targetWeightKg = ImperialUnits.lbsToKg(targetWeightLbs)
        updated.activityLevel = activityLevel
        updated.goals = Array(goals)

        // Calculate personalized goals
        let tdee = updated.tdee
        let calGoal: Double
        if goals.contains(.loseWeight) {
            calGoal = tdee - 500    // 500 kcal deficit
        } else if goals.contains(.gainMuscle) {
            calGoal = tdee + 300
        } else {
            calGoal = tdee
        }
        updated.dailyCalorieGoal = calGoal
        updated.dailyProteinGoal = updated.weightKg * 2.0   // 2g/kg
        updated.dailyCarbGoal    = (calGoal * 0.45) / 4.0
        updated.dailyFatGoal     = (calGoal * 0.25) / 9.0

        Task {
            try? await authService.updateProfile(updated)
            authService.onboardingComplete = true
            isCompleting = false
        }
    }
}

// MARK: - Progress Bar
struct OnboardingProgressBar: View {
    var current: Int
    var total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? AppTheme.accent : AppTheme.borderSubtle)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: current)
            }
        }
    }
}

// MARK: - Welcome Page
struct OnboardingWelcomePage: View {
    @Binding var step: Int
    @State private var animate = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 32) {
                // App icon hero
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.1))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(AppTheme.gradientPrimary)
                            .frame(width: 110, height: 110)
                            .shadow(color: AppTheme.accent.opacity(0.6), radius: 24, y: 8)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 54))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(animate ? 1.0 : 0.7)
                .opacity(animate ? 1.0 : 0)

                VStack(spacing: 12) {
                    Text("Welcome to\nHealth Insight Pro")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Your all-in-one health companion.\nTrack, analyze, and improve every aspect of your wellbeing.")
                        .font(AppFont.callout())
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .opacity(animate ? 1.0 : 0)
                .offset(y: animate ? 0 : 20)
            }
            Spacer()
            OnboardingContinueButton(title: "Get Started") {
                withAnimation { step = 1 }
            }
            .padding(.horizontal, 28).padding(.bottom, 50)
            .opacity(animate ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2)) {
                animate = true
            }
        }
    }
}

// MARK: - Goals Page
struct OnboardingGoalsPage: View {
    @Binding var goals: Set<HealthGoal>
    @Binding var step: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingPageHeader(
                    step: "Step 1",
                    title: "What are your\nhealth goals?",
                    subtitle: "Select all that apply. We'll personalize your experience."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(HealthGoal.allCases, id: \.self) { goal in
                        GoalSelectionCard(goal: goal, isSelected: goals.contains(goal)) {
                            HapticFeedback.selection()
                            if goals.contains(goal) {
                                goals.remove(goal)
                            } else {
                                goals.insert(goal)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                OnboardingContinueButton(title: "Continue") {
                    withAnimation { step = 2 }
                }
                .disabled(goals.isEmpty)
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }
}

struct GoalSelectionCard: View {
    var goal: HealthGoal
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.accent : AppTheme.cardBackgroundAlt)
                        .frame(width: 50, height: 50)
                    Image(systemName: goal.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                }
                Text(goal.displayName)
                    .font(AppFont.subheadline(.semibold))
                    .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? AppTheme.accent : AppTheme.borderSubtle, lineWidth: isSelected ? 1.5 : 1))
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Body Metrics Page
struct OnboardingBodyMetricsPage: View {
    @Binding var sex: BiologicalSex
    @Binding var dob: Date
    @Binding var heightInches: Double
    @Binding var weightLbs: Double
    @Binding var step: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingPageHeader(step: "Step 2", title: "Tell us about\nyourself", subtitle: "This helps us calculate your personalized goals.")

                VStack(spacing: 16) {
                    // Sex
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Biological Sex")
                            .font(AppFont.subheadline(.semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 24)
                        HStack(spacing: 12) {
                            ForEach(BiologicalSex.allCases, id: \.self) { s in
                                Button(s.displayName) { sex = s }
                                    .font(AppFont.subheadline(.semibold))
                                    .foregroundColor(sex == s ? .white : AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity).frame(height: 44)
                                    .background(sex == s ? AppTheme.accent : AppTheme.cardBackground)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Date of Birth
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date of Birth")
                            .font(AppFont.subheadline(.semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 24)
                        DatePicker("", selection: $dob, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .padding(.horizontal, 24)
                    }

                    // Height slider
                    OnboardingSliderRow(
                        title: "Height",
                        value: $heightInches,
                        range: 52...84,
                        unit: "in",
                        format: "%.0f",
                        valueText: ImperialUnits.feetAndInchesString(fromInches: heightInches)
                    )
                    // Weight slider
                    OnboardingSliderRow(title: "Current Weight", value: $weightLbs,
                                        range: 80...550, unit: "lb", format: "%.1f")
                }

                OnboardingContinueButton(title: "Continue") {
                    withAnimation { step = 3 }
                }
                .padding(.horizontal, 28).padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Target Page
struct OnboardingTargetPage: View {
    @Binding var targetWeightLbs: Double
    var currentWeightLbs: Double
    @Binding var step: Int

    var body: some View {
        VStack(spacing: 24) {
            OnboardingPageHeader(step: "Step 3", title: "Set your\nweight goal", subtitle: "We'll create a personalized calorie plan to get you there.")
            Spacer()
            VStack(spacing: 20) {
                // Current vs Target
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Current")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        Text(currentWeightLbs.formatted1)
                            .font(AppFont.metric())
                            .foregroundColor(AppTheme.textPrimary)
                        Text("lb")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Image(systemName: "arrow.right")
                        .foregroundColor(AppTheme.textTertiary)
                    VStack(spacing: 4) {
                        Text("Target")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        Text(targetWeightLbs.formatted1)
                            .font(AppFont.metric())
                            .foregroundStyle(AppTheme.gradientPrimary)
                        Text("lb")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .cardStyle()
                .padding(.horizontal, 24)

                OnboardingSliderRow(title: "Target Weight", value: $targetWeightLbs,
                                    range: 80...550, unit: "lb", format: "%.1f")
            }
            Spacer()
            OnboardingContinueButton(title: "Continue") {
                withAnimation { step = 4 }
            }
            .padding(.horizontal, 28).padding(.bottom, 50)
        }
    }
}

// MARK: - Activity Level Page
struct OnboardingActivityPage: View {
    @Binding var activityLevel: ActivityLevel
    @Binding var step: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingPageHeader(step: "Step 4", title: "How active\nare you?", subtitle: "This determines your daily calorie needs.")

                VStack(spacing: 12) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        ActivityLevelCard(level: level, isSelected: activityLevel == level) {
                            HapticFeedback.selection()
                            activityLevel = level
                        }
                    }
                }
                .padding(.horizontal, 24)

                OnboardingContinueButton(title: "Continue") {
                    withAnimation { step = 5 }
                }
                .padding(.horizontal, 28).padding(.bottom, 40)
            }
        }
    }
}

struct ActivityLevelCard: View {
    var level: ActivityLevel
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.accent : AppTheme.cardBackgroundAlt)
                        .frame(width: 44, height: 44)
                    Image(systemName: level.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(level.displayName)
                        .font(AppFont.headline(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(level.description)
                        .font(AppFont.caption())
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accent)
                }
            }
            .padding(16)
            .background(isSelected ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? AppTheme.accent : AppTheme.borderSubtle, lineWidth: isSelected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Permissions Page
struct OnboardingPermissionsPage: View {
    @Binding var healthKitGranted: Bool
    @Binding var step: Int
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 32) {
                OnboardingPageHeader(step: "Step 5", title: "Connect\nHealth Data",
                                     subtitle: "Sync your Apple Health data for automatic tracking.")

                VStack(spacing: 14) {
                    PermissionRow(icon: "figure.walk", color: AppTheme.accentBlue, title: "Steps & Activity", desc: "Track your daily movement")
                    PermissionRow(icon: "heart.fill", color: AppTheme.accentPink, title: "Heart Rate & HRV", desc: "Monitor your cardiovascular health")
                    PermissionRow(icon: "moon.stars.fill", color: AppTheme.accentYellow, title: "Sleep Analysis", desc: "Understand your sleep stages")
                    PermissionRow(icon: "scalemass.fill", color: AppTheme.accentGreen, title: "Body Measurements", desc: "Weight and body composition")
                    PermissionRow(icon: "drop.fill", color: AppTheme.accentBlue, title: "Nutrition", desc: "Sync meal and nutrition data")
                }
                .padding(.horizontal, 24)
            }
            Spacer()
            VStack(spacing: 12) {
                Button {
                    Task {
                        try? await HealthKitService.shared.requestAuthorization()
                        healthKitGranted = true
                        HapticFeedback.success()
                        onComplete()
                    }
                } label: {
                    HStack {
                        Image(systemName: "heart.text.square.fill")
                        Text("Connect Apple Health")
                    }
                    .font(AppFont.headline())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(AppTheme.gradientPrimary)
                    .cornerRadius(16)
                }

                Button("Skip for now") { onComplete() }
                    .font(AppFont.subheadline())
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 28).padding(.bottom, 50)
        }
    }
}

struct PermissionRow: View {
    var icon: String
    var color: Color
    var title: String
    var desc: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.headline(.semibold)).foregroundColor(AppTheme.textPrimary)
                Text(desc).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.accentGreen.opacity(0.6))
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Reusable Onboarding Components
struct OnboardingPageHeader: View {
    var step: String
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step.uppercased())
                .font(AppFont.caption(.bold))
                .foregroundColor(AppTheme.accent)
                .tracking(2)
            Text(title)
                .font(AppFont.largeTitle())
                .foregroundColor(AppTheme.textPrimary)
            Text(subtitle)
                .font(AppFont.callout())
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}

struct OnboardingContinueButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            Text(title)
                .font(AppFont.headline())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(AppTheme.gradientPrimary)
                .cornerRadius(16)
                .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingSliderRow: View {
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var unit: String
    var format: String
    var valueText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(AppFont.subheadline(.semibold))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text(valueText ?? String(format: "\(format) \(unit)", value))
                    .font(AppFont.headline(.bold))
                    .foregroundColor(AppTheme.accent)
            }
            .padding(.horizontal, 24)
            Slider(value: $value, in: range)
                .tint(AppTheme.accent)
                .padding(.horizontal, 24)
        }
    }
}
