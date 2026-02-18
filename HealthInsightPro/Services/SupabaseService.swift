import Foundation
import Supabase

// MARK: - Supabase Client Singleton
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Constants.Supabase.url)!,
            supabaseKey: Constants.Supabase.anonKey
        )
    }

    // MARK: - User Profile
    func saveProfile(_ profile: UserProfile) async throws {
        try await client.from("user_profiles")
            .upsert(profile)
            .execute()
    }

    func fetchProfile(userId: UUID) async throws -> UserProfile? {
        let response = try await client.from("user_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
        return try response.value
    }

    func updateProfile(_ profile: UserProfile) async throws {
        try await client.from("user_profiles")
            .update(profile)
            .eq("id", value: profile.id.uuidString)
            .execute()
    }

    // MARK: - Meal Entries
    func saveMealEntry(_ entry: MealEntry) async throws {
        try await client.from("meal_entries")
            .upsert(entry)
            .execute()
    }

    func fetchMealEntries(userId: UUID, date: Date) async throws -> [MealEntry] {
        let start = date.startOfDay.iso8601
        let end = date.endOfDay.iso8601
        let response = try await client.from("meal_entries")
            .select("*, items:meal_entry_items(*, food_item:food_items(*))")
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: start)
            .lte("logged_at", value: end)
            .order("logged_at")
            .execute()
        return (try? response.value) ?? []
    }

    func deleteMealEntry(id: UUID) async throws {
        try await client.from("meal_entries")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Food Items
    func searchFoodItems(query: String, limit: Int = 25) async throws -> [FoodItem] {
        let response = try await client.from("food_items")
            .select()
            .ilike("name", pattern: "%\(query)%")
            .limit(limit)
            .execute()
        return (try? response.value) ?? []
    }

    func fetchFoodItemByBarcode(_ barcode: String) async throws -> FoodItem? {
        let response = try await client.from("food_items")
            .select()
            .eq("barcode", value: barcode)
            .single()
            .execute()
        return try? response.value
    }

    func saveCustomFoodItem(_ item: FoodItem) async throws {
        try await client.from("food_items")
            .insert(item)
            .execute()
    }

    // MARK: - Sleep Entries
    func saveSleepEntry(_ entry: SleepEntry) async throws {
        try await client.from("sleep_entries")
            .upsert(entry)
            .execute()
    }

    func fetchSleepEntries(userId: UUID, days: Int = 7) async throws -> [SleepEntry] {
        let since = Date().daysAgo(days).iso8601
        let response = try await client.from("sleep_entries")
            .select("*, stages:sleep_stage_segments(*)")
            .eq("user_id", value: userId.uuidString)
            .gte("start_time", value: since)
            .order("start_time", ascending: false)
            .execute()
        return (try? response.value) ?? []
    }

    func fetchLatestSleepEntry(userId: UUID) async throws -> SleepEntry? {
        let response = try await client.from("sleep_entries")
            .select("*, stages:sleep_stage_segments(*)")
            .eq("user_id", value: userId.uuidString)
            .order("start_time", ascending: false)
            .limit(1)
            .single()
            .execute()
        return try? response.value
    }

    // MARK: - Activity Entries
    func saveActivityEntry(_ entry: ActivityEntry) async throws {
        try await client.from("activity_entries")
            .upsert(entry)
            .execute()
    }

    func fetchActivityEntries(userId: UUID, days: Int = 7) async throws -> [ActivityEntry] {
        let since = Date().daysAgo(days).iso8601
        let response = try await client.from("activity_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("start_time", value: since)
            .order("start_time", ascending: false)
            .execute()
        return (try? response.value) ?? []
    }

    func saveDailyActivity(_ activity: DailyActivity) async throws {
        try await client.from("daily_activities")
            .upsert(activity)
            .execute()
    }

    func fetchDailyActivity(userId: UUID, date: Date) async throws -> DailyActivity? {
        let dateStr = date.startOfDay.iso8601
        let response = try await client.from("daily_activities")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: dateStr)
            .single()
            .execute()
        return try? response.value
    }

    // MARK: - Water Entries
    func saveWaterEntry(_ entry: WaterEntry) async throws {
        try await client.from("water_entries")
            .insert(entry)
            .execute()
    }

    func fetchWaterEntries(userId: UUID, date: Date) async throws -> [WaterEntry] {
        let start = date.startOfDay.iso8601
        let end = date.endOfDay.iso8601
        let response = try await client.from("water_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: start)
            .lte("logged_at", value: end)
            .order("logged_at")
            .execute()
        return (try? response.value) ?? []
    }

    func deleteWaterEntry(id: UUID) async throws {
        try await client.from("water_entries")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Weight Entries
    func saveWeightEntry(_ entry: WeightEntry) async throws {
        try await client.from("weight_entries")
            .insert(entry)
            .execute()
    }

    func fetchWeightEntries(userId: UUID, days: Int = 30) async throws -> [WeightEntry] {
        let since = Date().daysAgo(days).iso8601
        let response = try await client.from("weight_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: since)
            .order("logged_at", ascending: false)
            .execute()
        return (try? response.value) ?? []
    }

    // MARK: - Journal Entries
    func saveJournalEntry(_ entry: JournalEntry) async throws {
        try await client.from("journal_entries")
            .upsert(entry)
            .execute()
    }

    func fetchJournalEntries(userId: UUID, days: Int = 7) async throws -> [JournalEntry] {
        let since = Date().daysAgo(days).iso8601
        let response = try await client.from("journal_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: since)
            .order("date", ascending: false)
            .execute()
        return (try? response.value) ?? []
    }

    func fetchJournalEntry(userId: UUID, date: Date) async throws -> JournalEntry? {
        let dateStr = date.startOfDay.iso8601
        let response = try await client.from("journal_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: dateStr)
            .single()
            .execute()
        return try? response.value
    }

    // MARK: - Insight Scores
    func saveInsightScores(_ scores: InsightScores) async throws {
        try await client.from("insight_scores")
            .upsert(scores)
            .execute()
    }

    func fetchInsightScores(userId: UUID, days: Int = 7) async throws -> [InsightScores] {
        let since = Date().daysAgo(days).iso8601
        let response = try await client.from("insight_scores")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: since)
            .order("date", ascending: false)
            .execute()
        return (try? response.value) ?? []
    }

    // MARK: - Recipes
    func saveRecipe(_ recipe: Recipe) async throws {
        try await client.from("recipes")
            .upsert(recipe)
            .execute()
    }

    func fetchRecipes(userId: UUID) async throws -> [Recipe] {
        let response = try await client.from("recipes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        return (try? response.value) ?? []
    }

    func deleteRecipe(id: UUID) async throws {
        try await client.from("recipes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Blood Metrics
    func saveBloodMetric(_ metric: BloodMetric) async throws {
        try await client.from("blood_metrics")
            .insert(metric)
            .execute()
    }

    func fetchBloodMetrics(userId: UUID, days: Int = 30) async throws -> [BloodMetric] {
        let since = Date().daysAgo(days).iso8601
        let response = try await client.from("blood_metrics")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("recorded_at", value: since)
            .order("recorded_at", ascending: false)
            .execute()
        return (try? response.value) ?? []
    }
}
