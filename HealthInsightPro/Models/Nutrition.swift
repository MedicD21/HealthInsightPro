import Foundation

// MARK: - Macros / Nutrients
struct Macros: Codable {
    var calories: Double
    var protein: Double    // g
    var carbs: Double      // g
    var fat: Double        // g
    var fiber: Double      // g
    var sugar: Double      // g
    var sodium: Double     // mg
    var cholesterol: Double // mg
    var saturatedFat: Double // g
    var transFat: Double   // g
    var potassium: Double  // mg
    var vitaminA: Double?  // % DV
    var vitaminC: Double?  // % DV
    var calcium: Double?   // % DV
    var iron: Double?      // % DV

    static var zero: Macros {
        Macros(calories: 0, protein: 0, carbs: 0, fat: 0,
               fiber: 0, sugar: 0, sodium: 0, cholesterol: 0,
               saturatedFat: 0, transFat: 0, potassium: 0)
    }

    static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber,
            sugar: lhs.sugar + rhs.sugar,
            sodium: lhs.sodium + rhs.sodium,
            cholesterol: lhs.cholesterol + rhs.cholesterol,
            saturatedFat: lhs.saturatedFat + rhs.saturatedFat,
            transFat: lhs.transFat + rhs.transFat,
            potassium: lhs.potassium + rhs.potassium
        )
    }

    func scaled(by factor: Double) -> Macros {
        Macros(
            calories: calories * factor,
            protein: protein * factor,
            carbs: carbs * factor,
            fat: fat * factor,
            fiber: fiber * factor,
            sugar: sugar * factor,
            sodium: sodium * factor,
            cholesterol: cholesterol * factor,
            saturatedFat: saturatedFat * factor,
            transFat: transFat * factor,
            potassium: potassium * factor
        )
    }

    enum CodingKeys: String, CodingKey {
        case calories, protein, carbs, fat, fiber, sugar, sodium, cholesterol
        case saturatedFat = "saturated_fat"
        case transFat = "trans_fat"
        case potassium, vitaminA = "vitamin_a", vitaminC = "vitamin_c"
        case calcium, iron
    }
}

// MARK: - Food Item (from database)
struct FoodItem: Codable, Identifiable {
    var id: UUID
    var name: String
    var brand: String?
    var barcode: String?
    var servingSize: Double   // grams
    var servingUnit: String   // "g", "ml", "oz", "cup" etc.
    var servingDescription: String?  // "1 cup (240g)"
    var macrosPerServing: Macros
    var isCustom: Bool
    var userId: UUID?         // if user-created

    var caloriesPerGram: Double { macrosPerServing.calories / servingSize }

    enum CodingKeys: String, CodingKey {
        case id, name, brand, barcode
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
        case servingDescription = "serving_description"
        case macrosPerServing = "macros_per_serving"
        case isCustom = "is_custom"
        case userId = "user_id"
    }
}

// MARK: - Meal Entry Item (a logged food)
struct MealEntryItem: Codable, Identifiable {
    var id: UUID
    var foodItem: FoodItem
    var servings: Double     // number of servings
    var servingSize: Double? // override serving size in grams

    var totalMacros: Macros {
        foodItem.macrosPerServing.scaled(by: servings)
    }

    enum CodingKeys: String, CodingKey {
        case id, servings
        case foodItem = "food_item"
        case servingSize = "serving_size"
    }
}

// MARK: - Meal Type
enum MealType: String, CaseIterable, Codable {
    case breakfast = "breakfast"
    case lunch     = "lunch"
    case dinner    = "dinner"
    case snack     = "snack"
    case preworkout = "pre_workout"
    case postworkout = "post_workout"

    var displayName: String {
        switch self {
        case .breakfast:   return "Breakfast"
        case .lunch:       return "Lunch"
        case .dinner:      return "Dinner"
        case .snack:       return "Snack"
        case .preworkout:  return "Pre-Workout"
        case .postworkout: return "Post-Workout"
        }
    }
    var icon: String {
        switch self {
        case .breakfast:   return "sun.horizon.fill"
        case .lunch:       return "sun.max.fill"
        case .dinner:      return "moon.fill"
        case .snack:       return "carrot.fill"
        case .preworkout:  return "bolt.fill"
        case .postworkout: return "arrow.up.heart.fill"
        }
    }
    var defaultTime: String {
        switch self {
        case .breakfast:   return "8:00 AM"
        case .lunch:       return "12:30 PM"
        case .dinner:      return "7:00 PM"
        case .snack:       return "3:00 PM"
        case .preworkout:  return "5:30 PM"
        case .postworkout: return "7:30 PM"
        }
    }
}

// MARK: - Meal Log Entry (one meal)
struct MealEntry: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var mealType: MealType
    var items: [MealEntryItem]
    var loggedAt: Date
    var notes: String?
    var imageUrl: String?

    var totalMacros: Macros {
        items.reduce(Macros.zero) { $0 + $1.totalMacros }
    }

    enum CodingKeys: String, CodingKey {
        case id, items, notes
        case userId = "user_id"
        case mealType = "meal_type"
        case loggedAt = "logged_at"
        case imageUrl = "image_url"
    }
}

// MARK: - Nutrition Day Summary
struct NutritionDaySummary {
    var date: Date
    var meals: [MealEntry]
    var calorieGoal: Double
    var proteinGoal: Double
    var carbGoal: Double
    var fatGoal: Double

    var totalMacros: Macros {
        meals.reduce(Macros.zero) { $0 + $1.totalMacros }
    }
    var caloriesRemaining: Double { calorieGoal - totalMacros.calories }
    var proteinProgress: Double { (totalMacros.protein / proteinGoal).clamped01 }
    var carbProgress: Double { (totalMacros.carbs / carbGoal).clamped01 }
    var fatProgress: Double { (totalMacros.fat / fatGoal).clamped01 }
    var calorieProgress: Double { (totalMacros.calories / calorieGoal).clamped01 }
}

// MARK: - Recipe
struct Recipe: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var name: String
    var description: String?
    var servings: Int
    var ingredients: [MealEntryItem]
    var imageUrl: String?
    var tags: [String]
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var createdAt: Date

    var totalMacros: Macros {
        ingredients.reduce(Macros.zero) { $0 + $1.totalMacros }
    }
    var macrosPerServing: Macros {
        totalMacros.scaled(by: 1.0 / Double(max(1, servings)))
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, servings, ingredients, tags
        case userId = "user_id"
        case imageUrl = "image_url"
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case createdAt = "created_at"
    }
}

// MARK: - Meal Plan
struct MealPlan: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var name: String
    var weekStartDate: Date
    var days: [MealPlanDay]
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, days
        case userId = "user_id"
        case weekStartDate = "week_start_date"
        case createdAt = "created_at"
    }
}

struct MealPlanDay: Codable {
    var dayOfWeek: Int   // 0 = Sunday
    var meals: [MealPlanMeal]
}

struct MealPlanMeal: Codable, Identifiable {
    var id: UUID
    var mealType: MealType
    var foodItems: [MealEntryItem]
    var recipeId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case mealType = "meal_type"
        case foodItems = "food_items"
        case recipeId = "recipe_id"
    }
}
