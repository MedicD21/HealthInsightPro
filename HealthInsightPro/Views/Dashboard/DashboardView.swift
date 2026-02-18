import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var vm = DashboardViewModel()
    @State private var selectedTab: MainTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeTab()
                    .environmentObject(vm)
                    .environmentObject(authService)
                    .tabItem { Label(MainTab.dashboard.title, systemImage: MainTab.dashboard.icon) }
                    .tag(MainTab.dashboard)

                NutritionView()
                    .tabItem { Label(MainTab.nutrition.title, systemImage: MainTab.nutrition.icon) }
                    .tag(MainTab.nutrition)

                ActivityView()
                    .tabItem { Label(MainTab.activity.title, systemImage: MainTab.activity.icon) }
                    .tag(MainTab.activity)

                SleepView()
                    .tabItem { Label(MainTab.sleep.title, systemImage: MainTab.sleep.icon) }
                    .tag(MainTab.sleep)

                InsightsView()
                    .tabItem { Label(MainTab.insights.title, systemImage: MainTab.insights.icon) }
                    .tag(MainTab.insights)

                ProfileView()
                    .environmentObject(authService)
                    .tabItem { Label(MainTab.profile.title, systemImage: MainTab.profile.icon) }
                    .tag(MainTab.profile)
            }
            .tint(AppTheme.colorFor(tab: selectedTab))
        }
        .preferredColorScheme(.dark)
        .task {
            if let profile = authService.currentUser {
                await vm.load(userId: profile.id, profile: profile)
            }
        }
    }
}

// MARK: - Home Tab
struct HomeTab: View {
    @EnvironmentObject var vm: DashboardViewModel
    @EnvironmentObject var authService: AuthService

    var profile: UserProfile? { authService.currentUser }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header
                        DashboardHeader(vm: vm, profile: profile)
                        // Calorie Hero Card
                        CalorieHeroCard(vm: vm)
                        // Macros
                        MacrosSection(vm: vm)
                        // Score Section
                        InsightScoresSection(vm: vm)
                        // Quick Stats Grid
                        QuickStatsGrid(vm: vm)
                        // Recent Meals
                        RecentMealsSection(vm: vm)
                        // Sleep Card
                        SleepSummaryCard(vm: vm)
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.refresh() }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Dashboard Header
struct DashboardHeader: View {
    @ObservedObject var vm: DashboardViewModel
    var profile: UserProfile?

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(vm.greetingText)
                    .font(AppFont.callout())
                    .foregroundColor(AppTheme.textSecondary)
                Text(profile?.fullName?.components(separatedBy: " ").first ?? "Friend")
                    .font(AppFont.title1(.bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            Spacer()
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.gradientPrimary)
                    .frame(width: 44, height: 44)
                Text(String(profile?.fullName?.prefix(1) ?? "H"))
                    .font(AppFont.headline(.bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Calorie Hero Card
struct CalorieHeroCard: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.borderSubtle, lineWidth: 1))

            HStack(spacing: 20) {
                // Big ring
                ZStack {
                    RingProgressView(
                        progress: vm.calorieProgress,
                        lineWidth: 14,
                        size: 130,
                        gradient: AppTheme.gradientOrange,
                        backgroundColor: Color.white.opacity(0.06)
                    )
                    VStack(spacing: 2) {
                        Text("\(Int(vm.caloriesConsumed))")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("kcal")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    CalorieStat(label: "Consumed", value: "\(Int(vm.caloriesConsumed))", unit: "kcal", color: AppTheme.accentOrange)
                    CalorieStat(label: "Burned",   value: "\(Int(vm.activeCalories))",  unit: "kcal", color: AppTheme.accentPink)
                    CalorieStat(label: "Remaining",value: "\(Int(max(0, vm.caloriesRemaining)))", unit: "kcal", color: AppTheme.accentGreen)
                    // Goal
                    HStack {
                        Text("Goal")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("\(Int(vm.calorieGoal)) kcal")
                            .font(AppFont.caption(.semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
    }
}

struct CalorieStat: View {
    var label: String; var value: String; var unit: String; var color: Color
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value).font(AppFont.subheadline(.bold)).foregroundColor(AppTheme.textPrimary)
            Text(unit).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
        }
    }
}

// MARK: - Macros Section
struct MacrosSection: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Macros Today")

            VStack(spacing: 10) {
                MacroRow(label: "Protein", consumed: vm.proteinConsumed, goal: vm.proteinGoal, color: AppTheme.accentBlue)
                MacroRow(label: "Carbs",   consumed: vm.carbsConsumed,   goal: vm.carbGoal,    color: AppTheme.accentOrange)
                MacroRow(label: "Fat",     consumed: vm.fatConsumed,     goal: vm.fatGoal,     color: AppTheme.accentYellow)
            }
            .padding(Constants.Layout.padding)
            .cardStyle()
        }
    }
}

// MARK: - Insight Scores Section
struct InsightScoresSection: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today's Insights")

            HStack(spacing: 0) {
                if let scores = vm.insightScores {
                    ScoreBadge(score: scores.recoveryScore, label: "Recovery", color: AppTheme.accentTeal)
                    Divider().background(AppTheme.borderSubtle).frame(height: 60)
                    ScoreBadge(score: scores.stressScore, label: "Stress", color: AppTheme.accentPink)
                    Divider().background(AppTheme.borderSubtle).frame(height: 60)
                    ScoreBadge(score: scores.strainScore, label: "Strain", color: AppTheme.accentOrange)
                    Divider().background(AppTheme.borderSubtle).frame(height: 60)
                    ScoreBadge(score: scores.sleepScore, label: "Sleep", color: AppTheme.accentYellow)
                } else {
                    HStack {
                        ForEach(["Recovery", "Stress", "Strain", "Sleep"], id: \.self) { label in
                            ScoreBadge(score: 0, label: label, color: AppTheme.textTertiary)
                            if label != "Sleep" { Divider().frame(height: 60) }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .cardStyle()
        }
    }
}

// MARK: - Quick Stats Grid
struct QuickStatsGrid: View {
    @ObservedObject var vm: DashboardViewModel

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Daily Stats")
            LazyVGrid(columns: columns, spacing: 12) {
                MetricCard(
                    title: "Steps",
                    value: vm.steps.asSteps,
                    unit: "",
                    icon: "figure.walk",
                    iconColor: AppTheme.accentBlue,
                    progress: vm.stepProgress,
                    progressColor: AppTheme.accentBlue,
                    subtitle: "\(Int(vm.stepProgress * 100))% of \(vm.stepGoal.asSteps) goal"
                )
                MetricCard(
                    title: "Hydration",
                    value: "\(Int(vm.waterMl))",
                    unit: "ml",
                    icon: "drop.fill",
                    iconColor: AppTheme.accentTeal,
                    progress: vm.waterProgress,
                    progressColor: AppTheme.accentTeal,
                    subtitle: "\(Int(vm.waterGoal - vm.waterMl))ml remaining"
                )
                MetricCard(
                    title: "Active Cal",
                    value: "\(Int(vm.activeCalories))",
                    unit: "kcal",
                    icon: "flame.fill",
                    iconColor: AppTheme.accentOrange,
                    progressColor: AppTheme.accentOrange
                )
                MetricCard(
                    title: "Weight",
                    value: vm.latestWeight.map { String(format: "%.1f", $0) } ?? "--",
                    unit: "kg",
                    icon: "scalemass.fill",
                    iconColor: AppTheme.accentPurple
                )
            }
        }
    }
}

// MARK: - Recent Meals
struct RecentMealsSection: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        if !vm.recentMeals.isEmpty {
            VStack(spacing: 12) {
                SectionHeader(title: "Recent Meals", actionTitle: "See All") {}

                VStack(spacing: 8) {
                    ForEach(vm.recentMeals) { meal in
                        MealSummaryRow(meal: meal)
                    }
                }
                .padding(Constants.Layout.padding)
                .cardStyle()
            }
        }
    }
}

struct MealSummaryRow: View {
    var meal: MealEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.accentGreen.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: meal.mealType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.accentGreen)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.mealType.displayName)
                    .font(AppFont.subheadline(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("\(meal.items.count) item\(meal.items.count == 1 ? "" : "s")")
                    .font(AppFont.caption())
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(meal.totalMacros.calories))")
                    .font(AppFont.subheadline(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("kcal")
                    .font(AppFont.caption())
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

// MARK: - Sleep Summary Card
struct SleepSummaryCard: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Last Night's Sleep")

            if let sleep = vm.lastSleep {
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(sleep.durationString)
                            .font(AppFont.title2(.bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Duration")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Divider().background(AppTheme.borderSubtle).frame(height: 44)

                    VStack(spacing: 4) {
                        Text("\(sleep.overallScore)")
                            .font(AppFont.title2(.bold))
                            .foregroundColor(AppTheme.accentYellow)
                        Text("Score")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Divider().background(AppTheme.borderSubtle).frame(height: 44)

                    VStack(spacing: 4) {
                        Text("\(sleep.deepSleepMinutes)m")
                            .font(AppFont.title2(.bold))
                            .foregroundColor(AppTheme.accent)
                        Text("Deep")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Divider().background(AppTheme.borderSubtle).frame(height: 44)

                    VStack(spacing: 4) {
                        Text("\(sleep.remSleepMinutes)m")
                            .font(AppFont.title2(.bold))
                            .foregroundColor(AppTheme.accentPurple)
                        Text("REM")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Constants.Layout.padding)
                .cardStyle()
            } else {
                Text("No sleep data for last night")
                    .font(AppFont.subheadline())
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cardStyle()
            }
        }
    }
}
