import Foundation
import Combine

// MARK: - Search source tracking
enum FoodSearchSource {
    case openFoodFacts, supabase, combined
}

@MainActor
final class NutritionViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var mealEntries: [MealEntry] = []
    @Published var searchResults: [FoodItem] = []
    @Published var searchQuery: String = ""
    @Published var isSearching = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddMealSheet = false
    @Published var selectedMealType: MealType = .breakfast
    @Published var recipes: [Recipe] = []
    @Published var weeklyCalories: [(Date, Double)] = []

    // Barcode-specific state
    @Published var barcodeResult: FoodItem? = nil
    @Published var isBarcodeLoading = false
    @Published var barcodeError: String? = nil

    private let supabase = SupabaseService.shared
    private let off = OpenFoodFactsService.shared
    private var userId: UUID?
    private var searchTask: Task<Void, Never>?

    // MARK: - Computed
    var daySummary: NutritionDaySummary? {
        guard let profile = AuthService.shared.currentUser else { return nil }
        return NutritionDaySummary(
            date: selectedDate,
            meals: mealEntries,
            calorieGoal: profile.dailyCalorieGoal,
            proteinGoal: profile.dailyProteinGoal,
            carbGoal: profile.dailyCarbGoal,
            fatGoal: profile.dailyFatGoal
        )
    }

    var totalMacros: Macros {
        mealEntries.reduce(Macros.zero) { $0 + $1.totalMacros }
    }

    var mealsByType: [(MealType, [MealEntry])] {
        MealType.allCases.compactMap { type in
            let meals = mealEntries.filter { $0.mealType == type }
            return meals.isEmpty ? nil : (type, meals)
        }
    }

    // MARK: - Loading
    func load(userId: UUID) async {
        self.userId = userId
        isLoading = true
        await fetchMeals()
        await fetchRecipes()
        isLoading = false
    }

    func fetchMeals() async {
        guard let uid = userId else { return }
        mealEntries = (try? await supabase.fetchMealEntries(userId: uid, date: selectedDate)) ?? []
    }

    func fetchRecipes() async {
        guard let uid = userId else { return }
        recipes = (try? await supabase.fetchRecipes(userId: uid)) ?? []
    }

    // MARK: - Food Search (OFF primary + Supabase custom fallback)
    /// Searches Open Food Facts first (millions of products), then merges with any
    /// user-created custom items stored in Supabase. OFF results are deduplicated by barcode.
    func searchFood(query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            isSearching = true
            // Debounce: wait for user to stop typing
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }

            // Run both searches concurrently
            async let offResults  = off.searchProducts(query: query, pageSize: 30)
            async let dbResults   = supabase.searchFoodItems(query: query, limit: 10)

            let (offItems, dbItems) = await (offResults, (try? dbResults) ?? [])

            guard !Task.isCancelled else { return }

            // Merge: db custom items first (user-created), then OFF, deduplicated by barcode
            var seen = Set<String>()
            var merged: [FoodItem] = []

            for item in dbItems {
                merged.append(item)
                if let bc = item.barcode { seen.insert(bc) }
            }
            for item in offItems {
                if let bc = item.barcode, seen.contains(bc) { continue }
                if let bc = item.barcode { seen.insert(bc) }
                merged.append(item)
            }

            searchResults = merged
            isSearching = false
        }
    }

    // MARK: - Barcode Lookup (OFF primary → Supabase cache fallback)
    /// Looks up a barcode via Open Food Facts. Falls back to Supabase if not found.
    /// On success, optionally caches the result in Supabase for offline use.
    func lookupBarcode(_ barcode: String) async -> FoodItem? {
        isBarcodeLoading = true
        barcodeError = nil
        barcodeResult = nil

        // 1. Try Open Food Facts
        if let item = await off.lookupBarcode(barcode) {
            barcodeResult = item
            isBarcodeLoading = false
            // Cache in Supabase for offline / faster future lookups
            Task { try? await supabase.saveCustomFoodItem(item) }
            return item
        }

        // 2. Fall back to Supabase local cache
        if let item = try? await supabase.fetchFoodItemByBarcode(barcode) {
            barcodeResult = item
            isBarcodeLoading = false
            return item
        }

        // 3. Not found anywhere
        barcodeError = "Product not found. Try searching by name."
        isBarcodeLoading = false
        return nil
    }

    // MARK: - Meal Actions
    func addMealEntry(_ entry: MealEntry) async {
        do {
            try await supabase.saveMealEntry(entry)
            await fetchMeals()
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMealEntry(_ entry: MealEntry) async {
        do {
            try await supabase.deleteMealEntry(id: entry.id)
            mealEntries.removeAll { $0.id == entry.id }
            HapticFeedback.medium()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveRecipe(_ recipe: Recipe) async {
        do {
            try await supabase.saveRecipe(recipe)
            await fetchRecipes()
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func changeDate(to date: Date) async {
        selectedDate = date
        await fetchMeals()
    }

    func clearBarcodeState() {
        barcodeResult = nil
        barcodeError = nil
        isBarcodeLoading = false
    }
}
