import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var caloriesConsumed: Double = 0
    @Published var calorieGoal: Double = Constants.Defaults.calorieGoal
    @Published var steps: Int = 0
    @Published var stepGoal: Int = Constants.Defaults.stepGoal
    @Published var activeCalories: Double = 0
    @Published var waterMl: Double = 0
    @Published var waterGoal: Double = Constants.Defaults.waterGoal
    @Published var latestWeight: Double?
    @Published var lastSleep: SleepEntry?
    @Published var todayActivity: DailyActivity?
    @Published var insightScores: InsightScores?
    @Published var recentMeals: [MealEntry] = []
    @Published var weeklySteps: [(Date, Int)] = []
    @Published var weeklyCalories: [(Date, Double)] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Macros
    @Published var proteinConsumed: Double = 0
    @Published var carbsConsumed: Double = 0
    @Published var fatConsumed: Double = 0
    @Published var proteinGoal: Double = Constants.Defaults.proteinGoal
    @Published var carbGoal: Double = Constants.Defaults.carbGoal
    @Published var fatGoal: Double = Constants.Defaults.fatGoal

    private let supabase = SupabaseService.shared
    private let healthKit = HealthKitService.shared
    private var userId: UUID?

    // Computed
    var caloriesRemaining: Double { calorieGoal - caloriesConsumed }
    var calorieProgress: Double { (caloriesConsumed / calorieGoal).clamped01 }
    var stepProgress: Double { (Double(steps) / Double(stepGoal)).clamped01 }
    var waterProgress: Double { (waterMl / waterGoal).clamped01 }
    var proteinProgress: Double { (proteinConsumed / proteinGoal).clamped01 }
    var carbProgress: Double { (carbsConsumed / carbGoal).clamped01 }
    var fatProgress: Double { (fatConsumed / fatGoal).clamped01 }
    var sleepHours: Double { lastSleep?.totalDurationHours ?? 0 }
    var sleepScore: Int { lastSleep?.overallScore ?? 0 }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }

    func load(userId: UUID, profile: UserProfile) async {
        self.userId = userId
        calorieGoal = profile.dailyCalorieGoal
        proteinGoal = profile.dailyProteinGoal
        carbGoal = profile.dailyCarbGoal
        fatGoal = profile.dailyFatGoal
        waterGoal = profile.dailyWaterGoal
        stepGoal = profile.dailyStepGoal

        isLoading = true
        async let stepsTask = healthKit.fetchStepsToday()
        async let activeCalTask = healthKit.fetchActiveCaloriesToday()
        async let weeklyStepsTask = healthKit.fetchSteps(days: 7)
        async let sleepTask = fetchLatestSleep(userId: userId)
        async let mealsTask = fetchTodayMeals(userId: userId)
        async let waterTask = fetchTodayWater(userId: userId)
        async let weightTask = healthKit.fetchLatestWeight()

        steps = await stepsTask
        activeCalories = await activeCalTask
        weeklySteps = await weeklyStepsTask
        lastSleep = await sleepTask
        latestWeight = await weightTask

        let (meals, water) = await (mealsTask, waterTask)
        recentMeals = Array(meals.prefix(3))
        waterMl = water

        let allMacros = meals.reduce(Macros.zero) { $0 + $1.totalMacros }
        caloriesConsumed = allMacros.calories
        proteinConsumed  = allMacros.protein
        carbsConsumed    = allMacros.carbs
        fatConsumed      = allMacros.fat

        // Compute insights
        let nutritionSummary = NutritionDaySummary(
            date: selectedDate,
            meals: meals,
            calorieGoal: calorieGoal,
            proteinGoal: proteinGoal,
            carbGoal: carbGoal,
            fatGoal: fatGoal
        )
        insightScores = InsightScores.compute(
            sleep: lastSleep,
            nutrition: nutritionSummary,
            activity: todayActivity,
            water: waterMl,
            waterGoal: waterGoal
        )

        isLoading = false
    }

    func refresh() async {
        guard let uid = userId else { return }
        if let profile = AuthService.shared.currentUser {
            await load(userId: uid, profile: profile)
        }
    }

    private func fetchLatestSleep(userId: UUID) async -> SleepEntry? {
        // First try HealthKit
        if let hkSleep = await healthKit.fetchSleepLastNight() { return hkSleep }
        // Fall back to Supabase
        return try? await supabase.fetchLatestSleepEntry(userId: userId)
    }

    private func fetchTodayMeals(userId: UUID) async -> [MealEntry] {
        (try? await supabase.fetchMealEntries(userId: userId, date: selectedDate)) ?? []
    }

    private func fetchTodayWater(userId: UUID) async -> Double {
        let entries = (try? await supabase.fetchWaterEntries(userId: userId, date: selectedDate)) ?? []
        return entries.reduce(0) { $0 + $1.amountMl }
    }
}
