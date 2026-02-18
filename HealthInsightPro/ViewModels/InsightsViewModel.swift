import Foundation

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var insightScores: InsightScores?
    @Published var weeklyScores: [InsightScores] = []
    @Published var weeklySteps: [(Date, Int)] = []
    @Published var weeklySleep: [(Date, Double)] = []
    @Published var weeklyCalories: [(Date, Double)] = []
    @Published var weeklyWater: [(Date, Double)] = []
    @Published var isLoading = false

    private let supabase = SupabaseService.shared
    private let healthKit = HealthKitService.shared
    private var userId: UUID?

    var recoveryScore: Int  { insightScores?.recoveryScore ?? 0 }
    var stressScore: Int    { insightScores?.stressScore ?? 0 }
    var strainScore: Int    { insightScores?.strainScore ?? 0 }
    var readinessScore: Int { insightScores?.readinessScore ?? 0 }

    func load(userId: UUID) async {
        self.userId = userId
        isLoading = true

        async let scoresTask = supabase.fetchInsightScores(userId: userId, days: 7)
        async let stepsTask  = healthKit.fetchSteps(days: 7)
        async let sleepTask  = supabase.fetchSleepEntries(userId: userId, days: 7)

        weeklyScores = (try? await scoresTask) ?? []
        insightScores = weeklyScores.first
        weeklySteps = await stepsTask
        weeklySleep = ((try? await sleepTask) ?? []).map { ($0.startTime, $0.totalDurationHours) }

        isLoading = false
    }

    var avgRecovery: Int {
        guard !weeklyScores.isEmpty else { return 0 }
        return weeklyScores.map { $0.recoveryScore }.reduce(0,+) / weeklyScores.count
    }
    var avgStrain: Int {
        guard !weeklyScores.isEmpty else { return 0 }
        return weeklyScores.map { $0.strainScore }.reduce(0,+) / weeklyScores.count
    }
    var avgSleep: Double {
        guard !weeklySleep.isEmpty else { return 0 }
        return weeklySleep.map { $0.1 }.reduce(0,+) / Double(weeklySleep.count)
    }
}
