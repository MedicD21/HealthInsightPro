import Foundation

@MainActor
final class WaterViewModel: ObservableObject {
    @Published var waterEntries: [WaterEntry] = []
    @Published var totalMl: Double = 0
    @Published var goal: Double = Constants.Defaults.waterGoal
    @Published var isLoading = false
    @Published var weeklyIntake: [(Date, Double)] = []

    private let supabase = SupabaseService.shared
    private var userId: UUID?

    var progress: Double { (totalMl / goal).clamped01 }
    var remainingMl: Double { max(0, goal - totalMl) }
    var progressPercent: Int { Int(progress * 100) }

    func load(userId: UUID) async {
        self.userId = userId
        if let profile = AuthService.shared.currentUser {
            goal = profile.dailyWaterGoal
        }
        isLoading = true
        await fetchToday()
        isLoading = false
    }

    func fetchToday() async {
        guard let uid = userId else { return }
        waterEntries = (try? await supabase.fetchWaterEntries(userId: uid, date: Date())) ?? []
        totalMl = waterEntries.reduce(0) { $0 + $1.amountMl }
    }

    func addWater(_ ml: Double, container: WaterContainerType? = nil) async {
        guard let uid = userId else { return }
        let entry = WaterEntry(
            id: UUID(), userId: uid,
            amountMl: ml,
            loggedAt: Date(),
            containerType: container
        )
        do {
            try await supabase.saveWaterEntry(entry)
            waterEntries.append(entry)
            totalMl += ml
            HapticFeedback.light()
        } catch {
            print("Water save error: \(error)")
        }
    }

    func deleteEntry(_ entry: WaterEntry) async {
        do {
            try await supabase.deleteWaterEntry(id: entry.id)
            waterEntries.removeAll { $0.id == entry.id }
            totalMl -= entry.amountMl
            HapticFeedback.medium()
        } catch {
            print("Water delete error: \(error)")
        }
    }
}
