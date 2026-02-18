import Foundation
import Supabase

// MARK: - Supabase Client Singleton
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient
    private let foodItemSelectColumns = "id,name,brand,barcode,serving_size,serving_unit,serving_description,is_custom,user_id,calories,protein,carbs,fat,fiber,sugar,sodium,cholesterol,saturated_fat,trans_fat,potassium,vitamin_a,vitamin_c,calcium,iron"

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
        let profile: UserProfile = try await client.from("user_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        return profile
    }

    func updateProfile(_ profile: UserProfile) async throws {
        try await client.from("user_profiles")
            .update(profile)
            .eq("id", value: profile.id.uuidString)
            .execute()
    }

    // MARK: - Meal Entries
    func saveMealEntry(_ entry: MealEntry) async throws {
        let mealRow = MealEntryWrite(entry)
        try await client.from("meal_entries")
            .upsert(mealRow)
            .execute()

        // Replace items for this meal entry to keep updates idempotent.
        try await client.from("meal_entry_items")
            .delete()
            .eq("meal_entry_id", value: entry.id.uuidString)
            .execute()

        var itemRows: [MealEntryItemWrite] = []
        for item in entry.items {
            let persistedFood = try await persistFoodItemForMeal(item.foodItem, userId: entry.userId)
            itemRows.append(MealEntryItemWrite(item, mealEntryId: entry.id, foodItemId: persistedFood.id))
        }

        if !itemRows.isEmpty {
            try await client.from("meal_entry_items")
                .insert(itemRows)
                .execute()
        }
    }

    func fetchMealEntries(userId: UUID, date: Date) async throws -> [MealEntry] {
        let start = date.startOfDay.iso8601
        let end = date.endOfDay.iso8601
        let rows: [MealEntryRead] = try await client.from("meal_entries")
            .select("id,user_id,meal_type,logged_at,notes,image_url,items:meal_entry_items(id,servings,serving_size,food_item:food_items(\(foodItemSelectColumns)))")
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: start)
            .lte("logged_at", value: end)
            .order("logged_at")
            .execute()
            .value
        return rows.map(\.mealEntry)
    }

    func deleteMealEntry(id: UUID) async throws {
        try await client.from("meal_entries")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Food Items
    func searchFoodItems(query: String, limit: Int = 25) async throws -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let rows: [FoodItemDBRow] = try await client.from("food_items")
            .select(foodItemSelectColumns)
            .ilike("name", pattern: "%\(trimmed)%")
            .limit(limit)
            .execute()
            .value
        return rows.map(\.foodItem)
    }

    func fetchFoodItemByBarcode(_ barcode: String) async throws -> FoodItem? {
        let normalized = normalizedBarcode(barcode)
        guard !normalized.isEmpty else { return nil }

        let rows: [FoodItemDBRow] = try await client.from("food_items")
            .select(foodItemSelectColumns)
            .eq("barcode", value: normalized)
            .limit(1)
            .execute()
            .value
        return rows.first?.foodItem
    }

    func fetchFoodItemById(_ id: UUID) async throws -> FoodItem? {
        let rows: [FoodItemDBRow] = try await client.from("food_items")
            .select(foodItemSelectColumns)
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first?.foodItem
    }

    @discardableResult
    func saveCustomFoodItem(_ item: FoodItem, ownerId: UUID? = nil) async throws -> FoodItem {
        if let barcode = item.barcode, let existing = try? await fetchFoodItemByBarcode(barcode) {
            return existing
        }

        let insertRow = FoodItemInsert(item: item, ownerId: ownerId)
        let row: FoodItemDBRow = try await client.from("food_items")
            .insert(insertRow)
            .select(foodItemSelectColumns)
            .single()
            .execute()
            .value
        return row.foodItem
    }

    // MARK: - Sleep Entries
    func saveSleepEntry(_ entry: SleepEntry) async throws {
        try await client.from("sleep_entries")
            .upsert(entry)
            .execute()
    }

    func fetchSleepEntries(userId: UUID, days: Int = 7) async throws -> [SleepEntry] {
        let since = Date().daysAgo(days).iso8601
        let rows: [SleepEntry] = try await client.from("sleep_entries")
            .select("*, stages:sleep_stage_segments(*)")
            .eq("user_id", value: userId.uuidString)
            .gte("start_time", value: since)
            .order("start_time", ascending: false)
            .execute()
            .value
        return rows
    }

    func fetchLatestSleepEntry(userId: UUID) async throws -> SleepEntry? {
        try? await client.from("sleep_entries")
            .select("*, stages:sleep_stage_segments(*)")
            .eq("user_id", value: userId.uuidString)
            .order("start_time", ascending: false)
            .limit(1)
            .single()
            .execute()
            .value
    }

    // MARK: - Activity Entries
    func saveActivityEntry(_ entry: ActivityEntry) async throws {
        try await client.from("activity_entries")
            .upsert(entry)
            .execute()
    }

    func fetchActivityEntries(userId: UUID, days: Int = 7) async throws -> [ActivityEntry] {
        let since = Date().daysAgo(days).iso8601
        let rows: [ActivityEntry] = try await client.from("activity_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("start_time", value: since)
            .order("start_time", ascending: false)
            .execute()
            .value
        return rows
    }

    func saveDailyActivity(_ activity: DailyActivity) async throws {
        try await client.from("daily_activities")
            .upsert(activity)
            .execute()
    }

    func fetchDailyActivity(userId: UUID, date: Date) async throws -> DailyActivity? {
        let dateStr = date.startOfDay.iso8601
        return try? await client.from("daily_activities")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: dateStr)
            .single()
            .execute()
            .value
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
        let rows: [WaterEntry] = try await client.from("water_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: start)
            .lte("logged_at", value: end)
            .order("logged_at")
            .execute()
            .value
        return rows
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
        let rows: [WeightEntry] = try await client.from("weight_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("logged_at", value: since)
            .order("logged_at", ascending: false)
            .execute()
            .value
        return rows
    }

    // MARK: - Journal Entries
    func saveJournalEntry(_ entry: JournalEntry) async throws {
        try await client.from("journal_entries")
            .upsert(entry)
            .execute()
    }

    func fetchJournalEntries(userId: UUID, days: Int = 7) async throws -> [JournalEntry] {
        let since = Date().daysAgo(days).iso8601
        let rows: [JournalEntry] = try await client.from("journal_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: since)
            .order("date", ascending: false)
            .execute()
            .value
        return rows
    }

    func fetchJournalEntry(userId: UUID, date: Date) async throws -> JournalEntry? {
        let dateStr = date.startOfDay.iso8601
        return try? await client.from("journal_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: dateStr)
            .single()
            .execute()
            .value
    }

    // MARK: - Insight Scores
    func saveInsightScores(_ scores: InsightScores) async throws {
        try await client.from("insight_scores")
            .upsert(scores)
            .execute()
    }

    func fetchInsightScores(userId: UUID, days: Int = 7) async throws -> [InsightScores] {
        let since = Date().daysAgo(days).iso8601
        let rows: [InsightScores] = try await client.from("insight_scores")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: since)
            .order("date", ascending: false)
            .execute()
            .value
        return rows
    }

    // MARK: - Recipes
    func saveRecipe(_ recipe: Recipe) async throws {
        try await client.from("recipes")
            .upsert(recipe)
            .execute()
    }

    func fetchRecipes(userId: UUID) async throws -> [Recipe] {
        let rows: [Recipe] = try await client.from("recipes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows
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
        let rows: [BloodMetric] = try await client.from("blood_metrics")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("recorded_at", value: since)
            .order("recorded_at", ascending: false)
            .execute()
            .value
        return rows
    }

    // MARK: - Nutrition Mapping Helpers
    private func normalizedBarcode(_ raw: String?) -> String {
        (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func persistFoodItemForMeal(_ item: FoodItem, userId: UUID) async throws -> FoodItem {
        if let barcode = item.barcode, !normalizedBarcode(barcode).isEmpty,
           let existing = try? await fetchFoodItemByBarcode(barcode) {
            return existing
        }

        if let existing = try? await fetchFoodItemById(item.id) {
            return existing
        }

        let ownerId = item.isCustom ? userId : nil
        return try await saveCustomFoodItem(item, ownerId: ownerId)
    }
}

// MARK: - Supabase Nutrition DTOs
private struct MealEntryWrite: Encodable {
    let id: UUID
    let userId: UUID
    let mealType: String
    let loggedAt: Date
    let notes: String?
    let imageUrl: String?

    init(_ entry: MealEntry) {
        self.id = entry.id
        self.userId = entry.userId
        self.mealType = entry.mealType.rawValue
        self.loggedAt = entry.loggedAt
        self.notes = entry.notes
        self.imageUrl = entry.imageUrl
    }

    enum CodingKeys: String, CodingKey {
        case id, notes
        case userId = "user_id"
        case mealType = "meal_type"
        case loggedAt = "logged_at"
        case imageUrl = "image_url"
    }
}

private struct MealEntryItemWrite: Encodable {
    let id: UUID
    let mealEntryId: UUID
    let foodItemId: UUID
    let servings: Double
    let servingSize: Double?

    init(_ item: MealEntryItem, mealEntryId: UUID, foodItemId: UUID) {
        self.id = item.id
        self.mealEntryId = mealEntryId
        self.foodItemId = foodItemId
        self.servings = item.servings
        self.servingSize = item.servingSize
    }

    enum CodingKeys: String, CodingKey {
        case id, servings
        case mealEntryId = "meal_entry_id"
        case foodItemId = "food_item_id"
        case servingSize = "serving_size"
    }
}

private struct MealEntryRead: Decodable {
    let id: UUID
    let userId: UUID
    let mealType: String
    let loggedAt: Date
    let notes: String?
    let imageUrl: String?
    let items: [MealEntryItemRead]

    var mealEntry: MealEntry {
        MealEntry(
            id: id,
            userId: userId,
            mealType: MealType(rawValue: mealType) ?? .snack,
            items: items.map(\.mealEntryItem),
            loggedAt: loggedAt,
            notes: notes,
            imageUrl: imageUrl
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, notes, items
        case userId = "user_id"
        case mealType = "meal_type"
        case loggedAt = "logged_at"
        case imageUrl = "image_url"
    }
}

private struct MealEntryItemRead: Decodable {
    let id: UUID
    let servings: Double
    let servingSize: Double?
    let foodItem: FoodItemDBRow

    var mealEntryItem: MealEntryItem {
        MealEntryItem(
            id: id,
            foodItem: foodItem.foodItem,
            servings: servings,
            servingSize: servingSize
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, servings
        case servingSize = "serving_size"
        case foodItem = "food_item"
    }
}

private struct FoodItemInsert: Encodable {
    let id: UUID
    let name: String
    let brand: String?
    let barcode: String?
    let servingSize: Double
    let servingUnit: String
    let servingDescription: String?
    let isCustom: Bool
    let userId: UUID?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let cholesterol: Double
    let saturatedFat: Double
    let transFat: Double
    let potassium: Double
    let vitaminA: Double?
    let vitaminC: Double?
    let calcium: Double?
    let iron: Double?

    init(item: FoodItem, ownerId: UUID?) {
        self.id = item.id
        self.name = item.name
        self.brand = item.brand
        self.barcode = item.barcode?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.servingSize = item.servingSize
        self.servingUnit = item.servingUnit
        self.servingDescription = item.servingDescription
        self.isCustom = ownerId != nil || item.isCustom
        self.userId = ownerId ?? item.userId
        self.calories = item.macrosPerServing.calories
        self.protein = item.macrosPerServing.protein
        self.carbs = item.macrosPerServing.carbs
        self.fat = item.macrosPerServing.fat
        self.fiber = item.macrosPerServing.fiber
        self.sugar = item.macrosPerServing.sugar
        self.sodium = item.macrosPerServing.sodium
        self.cholesterol = item.macrosPerServing.cholesterol
        self.saturatedFat = item.macrosPerServing.saturatedFat
        self.transFat = item.macrosPerServing.transFat
        self.potassium = item.macrosPerServing.potassium
        self.vitaminA = item.macrosPerServing.vitaminA
        self.vitaminC = item.macrosPerServing.vitaminC
        self.calcium = item.macrosPerServing.calcium
        self.iron = item.macrosPerServing.iron
    }

    enum CodingKeys: String, CodingKey {
        case id, name, brand, barcode
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case servingDescription = "serving_description"
        case isCustom = "is_custom"
        case userId = "user_id"
        case calories, protein, carbs, fat, fiber, sugar, sodium, cholesterol
        case saturatedFat = "saturated_fat"
        case transFat = "trans_fat"
        case potassium
        case vitaminA = "vitamin_a"
        case vitaminC = "vitamin_c"
        case calcium, iron
    }
}

private struct FoodItemDBRow: Decodable {
    let id: UUID
    let name: String
    let brand: String?
    let barcode: String?
    let servingSize: Double
    let servingUnit: String
    let servingDescription: String?
    let isCustom: Bool?
    let userId: UUID?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let cholesterol: Double?
    let saturatedFat: Double?
    let transFat: Double?
    let potassium: Double?
    let vitaminA: Double?
    let vitaminC: Double?
    let calcium: Double?
    let iron: Double?

    var foodItem: FoodItem {
        FoodItem(
            id: id,
            name: name,
            brand: brand,
            barcode: barcode,
            servingSize: servingSize,
            servingUnit: servingUnit,
            servingDescription: servingDescription,
            macrosPerServing: Macros(
                calories: calories ?? 0,
                protein: protein ?? 0,
                carbs: carbs ?? 0,
                fat: fat ?? 0,
                fiber: fiber ?? 0,
                sugar: sugar ?? 0,
                sodium: sodium ?? 0,
                cholesterol: cholesterol ?? 0,
                saturatedFat: saturatedFat ?? 0,
                transFat: transFat ?? 0,
                potassium: potassium ?? 0,
                vitaminA: vitaminA,
                vitaminC: vitaminC,
                calcium: calcium,
                iron: iron
            ),
            isCustom: isCustom ?? false,
            userId: userId
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, name, brand, barcode
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case servingDescription = "serving_description"
        case isCustom = "is_custom"
        case userId = "user_id"
        case calories, protein, carbs, fat, fiber, sugar, sodium, cholesterol
        case saturatedFat = "saturated_fat"
        case transFat = "trans_fat"
        case potassium
        case vitaminA = "vitamin_a"
        case vitaminC = "vitamin_c"
        case calcium, iron
    }
}
