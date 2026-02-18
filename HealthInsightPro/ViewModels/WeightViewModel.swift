import Foundation

@MainActor
final class WeightViewModel: ObservableObject {
    @Published var weightEntries: [WeightEntry] = []
    @Published var latestWeight: Double?
    @Published var targetWeight: Double?
    @Published var isLoading = false
    @Published var showLogWeight = false
    @Published var newWeightInput: String = ""
    @Published var newBodyFat: String = ""
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared
    private let healthKit = HealthKitService.shared
    private var userId: UUID?

    var startWeight: Double? { weightEntries.last?.weightKg }
    var weightChange: Double? {
        guard let l = latestWeight, let s = startWeight else { return nil }
        return l - s
    }
    var progressToGoal: Double? {
        guard let current = latestWeight, let target = targetWeight, let start = startWeight else { return nil }
        guard start != target else { return 1.0 }
        return ((start - current) / (start - target)).clamped01
    }
    var chartData: [(Date, Double)] {
        weightEntries.map { ($0.loggedAt, $0.weightKg) }.reversed()
    }
    var trend: [Double] {
        // Simple 7-day moving average
        let weights = chartData.map { $0.1 }
        return weights.enumerated().map { i, _ in
            let start = max(0, i - 3); let end = min(weights.count - 1, i + 3)
            return Array(weights[start...end]).reduce(0, +) / Double(end - start + 1)
        }
    }

    func load(userId: UUID) async {
        self.userId = userId
        targetWeight = AuthService.shared.currentUser?.targetWeightKg
        isLoading = true
        async let hkWeight = healthKit.fetchLatestWeight()
        async let entries = supabase.fetchWeightEntries(userId: userId, days: 90)
        latestWeight = await hkWeight
        weightEntries = (try? await entries) ?? []
        if latestWeight == nil { latestWeight = weightEntries.first?.weightKg }
        isLoading = false
    }

    func logWeight() async {
        guard let uid = userId, let lbs = Double(newWeightInput), lbs > 45, lbs < 1100 else {
            errorMessage = "Please enter a valid weight"
            return
        }
        let kg = ImperialUnits.lbsToKg(lbs)
        let bodyFat = Double(newBodyFat)
        let entry = WeightEntry(
            id: UUID(), userId: uid,
            weightKg: kg,
            bodyFatPercent: bodyFat,
            loggedAt: Date(),
            source: "manual"
        )
        do {
            try await supabase.saveWeightEntry(entry)
            try? await healthKit.saveWeight(kg: kg)
            weightEntries.insert(entry, at: 0)
            latestWeight = kg
            showLogWeight = false
            newWeightInput = ""
            newBodyFat = ""
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
