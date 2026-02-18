import Foundation

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var todayEntry: JournalEntry?
    @Published var recentEntries: [JournalEntry] = []
    @Published var isLoading = false
    @Published var isSaving = false

    // Entry editor state
    @Published var selectedMood: MoodLevel = .good
    @Published var energyLevel: Double = 7
    @Published var stressLevel: Double = 4
    @Published var notes: String = ""
    @Published var gratitudeNotes: String = ""
    @Published var meditated: Bool = false
    @Published var exercised: Bool = false
    @Published var alcoholConsumed: Bool = false
    @Published var alcoholServings: Int = 0
    @Published var medicationTaken: Bool = false
    @Published var medicationNotes: String = ""
    @Published var sunlightMinutes: Double = 20

    private let supabase = SupabaseService.shared
    private var userId: UUID?

    func load(userId: UUID) async {
        self.userId = userId
        isLoading = true
        todayEntry = try? await supabase.fetchJournalEntry(userId: userId, date: Date())
        recentEntries = (try? await supabase.fetchJournalEntries(userId: userId, days: 14)) ?? []
        if let existing = todayEntry { populate(from: existing) }
        isLoading = false
    }

    func saveEntry() async {
        guard let uid = userId else { return }
        isSaving = true
        let entry = JournalEntry(
            id: todayEntry?.id ?? UUID(),
            userId: uid,
            date: Date().startOfDay,
            mood: selectedMood,
            energyLevel: Int(energyLevel),
            stressLevel: Int(stressLevel),
            anxietyLevel: Int(stressLevel),
            notes: notes.isEmpty ? nil : notes,
            meditatedToday: meditated,
            exercisedToday: exercised,
            alcoholConsumed: alcoholConsumed,
            alcoholServings: alcoholConsumed ? alcoholServings : nil,
            smokingToday: false,
            medicationTaken: medicationTaken,
            medicationNotes: medicationNotes.isEmpty ? nil : medicationNotes,
            sunlightExposureMinutes: Int(sunlightMinutes),
            socialInteraction: true,
            gratitudeNotes: gratitudeNotes.isEmpty ? nil : gratitudeNotes,
            symptomsReported: [],
            tags: []
        )
        do {
            try await supabase.saveJournalEntry(entry)
            todayEntry = entry
            if !recentEntries.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
                recentEntries.insert(entry, at: 0)
            }
            HapticFeedback.success()
        } catch {
            print("Journal save error: \(error)")
        }
        isSaving = false
    }

    private func populate(from entry: JournalEntry) {
        selectedMood = entry.mood
        energyLevel = Double(entry.energyLevel)
        stressLevel = Double(entry.stressLevel)
        notes = entry.notes ?? ""
        gratitudeNotes = entry.gratitudeNotes ?? ""
        meditated = entry.meditatedToday
        exercised = entry.exercisedToday
        alcoholConsumed = entry.alcoholConsumed
        alcoholServings = entry.alcoholServings ?? 0
        medicationTaken = entry.medicationTaken
        medicationNotes = entry.medicationNotes ?? ""
        sunlightMinutes = Double(entry.sunlightExposureMinutes ?? 20)
    }
}
