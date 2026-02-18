import SwiftUI

struct InsightsView: View {
    @StateObject private var vm = InsightsViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Big 3 scores
                        InsightScoresHero(vm: vm)
                        // Readiness
                        ReadinessCard(vm: vm)
                        // Weekly trends
                        WeeklyTrendsSection(vm: vm)
                        // Wellness score
                        WellnessScoreCard(vm: vm)
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.load(userId: authService.currentUser!.id) }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            if let uid = authService.currentUser?.id {
                await vm.load(userId: uid)
            }
        }
    }
}

// MARK: - Scores Hero
struct InsightScoresHero: View {
    @ObservedObject var vm: InsightsViewModel

    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Today's Scores")

            HStack(spacing: 12) {
                ScoreCard(label: "Recovery", score: vm.recoveryScore, color: AppTheme.accentTeal,
                          icon: "bolt.heart.fill", description: "How ready your body is")
                ScoreCard(label: "Strain", score: vm.strainScore, color: AppTheme.accentOrange,
                          icon: "flame.fill", description: "Physical load on your body")
                ScoreCard(label: "Stress", score: vm.stressScore, color: AppTheme.accentPink,
                          icon: "brain.head.profile", description: "Overall stress level")
            }
        }
    }
}

struct ScoreCard: View {
    var label: String
    var score: Int
    var color: Color
    var icon: String
    var description: String

    var statusLabel: String {
        switch score {
        case 80...100: return "Excellent"
        case 60...79: return "Good"
        case 40...59: return "Fair"
        default: return "Low"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)

            ZStack {
                Circle()
                    .trim(from: 0, to: Double(score) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: score)
                Circle().stroke(color.opacity(0.15), lineWidth: 6)
                Text("\(score)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(width: 64, height: 64)

            Text(label)
                .font(AppFont.caption(.semibold))
                .foregroundColor(AppTheme.textPrimary)
            Text(statusLabel)
                .font(AppFont.caption())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

// MARK: - Readiness Card
struct ReadinessCard: View {
    @ObservedObject var vm: InsightsViewModel

    var readinessScore: Int { vm.readinessScore }
    var readinessColor: Color {
        switch readinessScore {
        case 80...100: return AppTheme.accentGreen
        case 60...79: return AppTheme.accentYellow
        case 40...59: return AppTheme.accentOrange
        default: return AppTheme.accentPink
        }
    }
    var readinessLabel: String {
        switch readinessScore {
        case 80...100: return "Peak Readiness"
        case 60...79: return "Ready to Train"
        case 40...59: return "Moderate Load"
        default: return "Rest Recommended"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Readiness")

            HStack(spacing: 20) {
                // Gauge
                ZStack {
                    Circle()
                        .trim(from: 0.25, to: 0.75)
                        .stroke(readinessColor.opacity(0.15),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(90))
                    Circle()
                        .trim(from: 0.25, to: 0.25 + 0.5 * Double(readinessScore) / 100.0)
                        .stroke(readinessColor,
                                style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(90))
                        .animation(.easeOut(duration: 0.8), value: readinessScore)
                    VStack(spacing: 2) {
                        Text("\(readinessScore)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("/100")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 12) {
                    Text(readinessLabel)
                        .font(AppFont.title3(.bold))
                        .foregroundColor(readinessColor)

                    VStack(alignment: .leading, spacing: 6) {
                        ReadinessFactorRow(label: "Sleep Quality", score: vm.insightScores?.sleepScore ?? 0)
                        ReadinessFactorRow(label: "Recovery", score: vm.insightScores?.recoveryScore ?? 0)
                        ReadinessFactorRow(label: "Hydration", score: vm.insightScores?.hydrationScore ?? 0)
                    }
                }
                Spacer()
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

struct ReadinessFactorRow: View {
    var label: String
    var score: Int

    var color: Color {
        switch score {
        case 70...100: return AppTheme.accentGreen
        case 40...69: return AppTheme.accentYellow
        default: return AppTheme.accentPink
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 90, alignment: .leading)
            LinearProgressBar(progress: Double(score) / 100.0, color: color, height: 5)
                .frame(width: 80)
            Text("\(score)")
                .font(AppFont.caption(.bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Weekly Trends
struct WeeklyTrendsSection: View {
    @ObservedObject var vm: InsightsViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "7-Day Trends")

            HStack(spacing: 12) {
                TrendCard(title: "Avg Recovery", value: "\(vm.avgRecovery)",
                          subtitle: "last 7 days", color: AppTheme.accentTeal, icon: "bolt.heart.fill")
                TrendCard(title: "Avg Strain", value: "\(vm.avgStrain)",
                          subtitle: "last 7 days", color: AppTheme.accentOrange, icon: "flame.fill")
            }

            HStack(spacing: 12) {
                TrendCard(title: "Avg Sleep", value: String(format: "%.1fh", vm.avgSleep),
                          subtitle: "per night", color: AppTheme.accentYellow, icon: "moon.stars.fill")
                TrendCard(title: "Avg Steps",
                          value: vm.weeklySteps.isEmpty ? "--" :
                            Int(vm.weeklySteps.map { Double($0.1) }.reduce(0,+) / Double(vm.weeklySteps.count)).asSteps,
                          subtitle: "per day", color: AppTheme.accentBlue, icon: "figure.walk")
            }
        }
    }
}

struct TrendCard: View {
    var title: String; var value: String; var subtitle: String; var color: Color; var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
                Text(title).font(AppFont.caption(.semibold)).foregroundColor(AppTheme.textSecondary)
            }
            Text(value)
                .font(AppFont.title2(.bold))
                .foregroundColor(AppTheme.textPrimary)
            Text(subtitle)
                .font(AppFont.caption())
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

// MARK: - Wellness Score
struct WellnessScoreCard: View {
    @ObservedObject var vm: InsightsViewModel

    var wellnessScore: Int { vm.insightScores?.overallWellnessScore ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Overall Wellness")

            HStack(spacing: 20) {
                ScoreGaugeView(score: wellnessScore, label: "Wellness", color: AppTheme.accent, size: 80)

                VStack(alignment: .leading, spacing: 10) {
                    WellnessBreakdown(label: "Sleep", score: vm.insightScores?.sleepScore ?? 0, color: AppTheme.accentYellow)
                    WellnessBreakdown(label: "Nutrition", score: vm.insightScores?.nutritionScore ?? 0, color: AppTheme.accentGreen)
                    WellnessBreakdown(label: "Hydration", score: vm.insightScores?.hydrationScore ?? 0, color: AppTheme.accentBlue)
                    WellnessBreakdown(label: "Recovery", score: vm.insightScores?.recoveryScore ?? 0, color: AppTheme.accentTeal)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

struct WellnessBreakdown: View {
    var label: String; var score: Int; var color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary).frame(width: 70, alignment: .leading)
            LinearProgressBar(progress: Double(score) / 100.0, color: color, height: 5)
            Text("\(score)").font(AppFont.caption(.bold)).foregroundColor(color).frame(width: 28)
        }
    }
}
