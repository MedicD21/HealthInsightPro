import Foundation

@MainActor
final class SleepViewModel: ObservableObject {
    @Published var sleepEntries: [SleepEntry] = []
    @Published var lastNightSleep: SleepEntry?
    @Published var sleepHabits: [SleepHabit] = []
    @Published var isLoading = false
    @Published var showLogSleepSheet = false
    @Published var errorMessage: String?

    // Manual log state
    @Published var bedtime: Date = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
    @Published var wakeTime: Date = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date()
    @Published var sleepQuality: Int = 7   // 1-10

    private let supabase = SupabaseService.shared
    private let healthKit = HealthKitService.shared
    private var userId: UUID?

    var avgSleepDuration: Double {
        guard !sleepEntries.isEmpty else { return 0 }
        return sleepEntries.map { $0.totalDurationHours }.reduce(0, +) / Double(sleepEntries.count)
    }
    var avgSleepScore: Int {
        guard !sleepEntries.isEmpty else { return 0 }
        return sleepEntries.map { $0.overallScore }.reduce(0, +) / sleepEntries.count
    }
    var weeklyScores: [(Date, Int)] {
        sleepEntries.map { ($0.startTime, $0.overallScore) }
    }

    func load(userId: UUID) async {
        self.userId = userId
        isLoading = true
        // Try HealthKit first
        if let hkSleep = await healthKit.fetchSleepLastNight() {
            lastNightSleep = hkSleep
        }
        sleepEntries = (try? await supabase.fetchSleepEntries(userId: userId, days: 14)) ?? []
        if lastNightSleep == nil { lastNightSleep = sleepEntries.first }
        isLoading = false
    }

    func logSleep() async {
        guard let uid = userId else { return }
        let stages = generateStages(bedtime: bedtime, wakeTime: wakeTime)
        let entry = SleepEntry(
            id: UUID(), userId: uid,
            startTime: bedtime, endTime: wakeTime,
            stages: stages, source: "manual",
            createdAt: Date()
        )
        do {
            try await supabase.saveSleepEntry(entry)
            sleepEntries.insert(entry, at: 0)
            lastNightSleep = entry
            showLogSleepSheet = false
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func generateStages(bedtime: Date, wakeTime: Date) -> [SleepStageSegment] {
        let totalMinutes = wakeTime.timeIntervalSince(bedtime) / 60
        guard totalMinutes > 30 else { return [] }

        // Approximate sleep architecture
        let deepMin   = totalMinutes * 0.20
        let remMin    = totalMinutes * 0.25
        let lightMin  = totalMinutes * 0.50
        let awakeMin  = totalMinutes * 0.05

        return [
            SleepStageSegment(id: UUID(), stage: .lightSleep, startTime: bedtime, durationMinutes: lightMin * 0.3),
            SleepStageSegment(id: UUID(), stage: .deepSleep,  startTime: bedtime.addingTimeInterval(lightMin*0.3*60), durationMinutes: deepMin * 0.5),
            SleepStageSegment(id: UUID(), stage: .remSleep,   startTime: bedtime.addingTimeInterval((lightMin*0.3+deepMin*0.5)*60), durationMinutes: remMin * 0.3),
            SleepStageSegment(id: UUID(), stage: .lightSleep, startTime: bedtime.addingTimeInterval(totalMinutes*0.4*60), durationMinutes: lightMin * 0.4),
            SleepStageSegment(id: UUID(), stage: .deepSleep,  startTime: bedtime.addingTimeInterval(totalMinutes*0.55*60), durationMinutes: deepMin * 0.3),
            SleepStageSegment(id: UUID(), stage: .remSleep,   startTime: bedtime.addingTimeInterval(totalMinutes*0.65*60), durationMinutes: remMin * 0.4),
            SleepStageSegment(id: UUID(), stage: .lightSleep, startTime: bedtime.addingTimeInterval(totalMinutes*0.75*60), durationMinutes: lightMin * 0.3),
            SleepStageSegment(id: UUID(), stage: .remSleep,   startTime: bedtime.addingTimeInterval(totalMinutes*0.85*60), durationMinutes: remMin * 0.3),
            SleepStageSegment(id: UUID(), stage: .awake,      startTime: wakeTime.addingTimeInterval(-awakeMin*60), durationMinutes: awakeMin)
        ]
    }
}
