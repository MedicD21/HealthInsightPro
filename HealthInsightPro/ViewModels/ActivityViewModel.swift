import Foundation

@MainActor
final class ActivityViewModel: ObservableObject {
    @Published var todayActivity: DailyActivity?
    @Published var workouts: [ActivityEntry] = []
    @Published var heartRate: Double?
    @Published var hrv: Double?
    @Published var vo2max: Double?
    @Published var weeklySteps: [(Date, Int)] = []
    @Published var weeklyCalories: [(Date, Double)] = []
    @Published var isLoading = false
    @Published var showLogWorkout = false
    @Published var errorMessage: String?
    @Published var tdeeBreakdown: TDEEBreakdown?

    // Workout log state
    @Published var selectedActivityType: ActivityType = .running
    @Published var workoutDurationMinutes: Double = 30
    @Published var workoutNotes: String = ""
    @Published var workoutStartTime: Date = Date()

    private let supabase = SupabaseService.shared
    private let healthKit = HealthKitService.shared
    private var userId: UUID?

    var steps: Int { todayActivity?.steps ?? 0 }
    var activeCalories: Double { todayActivity?.activeCalories ?? 0 }
    var distanceKm: Double { todayActivity?.distanceKm ?? 0 }
    var activeMinutes: Int { todayActivity?.activeMinutes ?? 0 }

    func load(userId: UUID) async {
        self.userId = userId
        isLoading = true

        async let stepsTask       = healthKit.fetchStepsToday()
        async let activeCalTask   = healthKit.fetchActiveCaloriesToday()
        async let restingCalTask  = healthKit.fetchRestingCaloriesToday()
        async let distanceTask    = healthKit.fetchDistanceToday()
        async let hrTask          = healthKit.fetchRestingHeartRate()
        async let hrvTask         = healthKit.fetchHeartRateVariability()
        async let vo2Task         = healthKit.fetchVO2Max()
        async let workoutsTask    = healthKit.fetchWorkouts(days: 7)
        async let weekStepsTask   = healthKit.fetchSteps(days: 7)

        let (s, ac, rc, dist, hr, hrv, vo2, wk, ws) = await (
            stepsTask, activeCalTask, restingCalTask, distanceTask,
            hrTask, hrvTask, vo2Task, workoutsTask, weekStepsTask
        )

        heartRate = hr
        self.hrv = hrv
        vo2max = vo2
        workouts = wk
        weeklySteps = ws
        weeklyCalories = weeklySteps.map { ($0.0, $0.1 > 0 ? Double($0.1) * 0.04 : 0) }

        todayActivity = DailyActivity(
            id: UUID(), userId: userId,
            date: Date().startOfDay,
            steps: s,
            distanceKm: dist,
            activeCalories: ac,
            restingCalories: rc,
            totalCalories: ac + rc,
            activeMinutes: Int(ac / 5),
            standingHours: Int(Double(s) / 1250),
            avgHeartRate: hr,
            restingHeartRate: hr
        )

        // TDEE
        if let profile = AuthService.shared.currentUser {
            tdeeBreakdown = TDEEBreakdown.calculate(
                profile: profile,
                dailyActivity: todayActivity,
                caloriesConsumed: profile.dailyCalorieGoal
            )
        }

        isLoading = false
    }

    func logWorkout() async {
        guard let uid = userId else { return }
        let duration = workoutDurationMinutes
        let end = workoutStartTime.addingTimeInterval(duration * 60)
        let weight = AuthService.shared.currentUser?.weightKg ?? 70
        let calories = selectedActivityType.metValue * weight * (duration / 60)

        let entry = ActivityEntry(
            id: UUID(), userId: uid,
            activityType: selectedActivityType,
            startTime: workoutStartTime,
            endTime: end,
            durationMinutes: duration,
            caloriesBurned: calories,
            source: "manual",
            notes: workoutNotes.isEmpty ? nil : workoutNotes,
            createdAt: Date()
        )
        do {
            try await supabase.saveActivityEntry(entry)
            workouts.insert(entry, at: 0)
            showLogWorkout = false
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
