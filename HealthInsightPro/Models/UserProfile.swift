import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    var id: UUID
    var appleUserId: String
    var email: String?
    var fullName: String?
    var avatarUrl: String?
    var dateOfBirth: Date?
    var biologicalSex: BiologicalSex
    var heightCm: Double
    var weightKg: Double
    var targetWeightKg: Double?
    var activityLevel: ActivityLevel
    var goals: [HealthGoal]

    // Calculated goals (stored after onboarding)
    var dailyCalorieGoal: Double
    var dailyProteinGoal: Double   // grams
    var dailyCarbGoal: Double      // grams
    var dailyFatGoal: Double       // grams
    var dailyWaterGoal: Double     // ml
    var dailyStepGoal: Int
    var nightlySleepGoal: Double   // hours
    var weeklyWorkoutGoal: Int

    var createdAt: Date
    var updatedAt: Date

    // MARK: Computed
    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }

    var bmi: Double {
        let hm = heightCm / 100.0
        guard hm > 0 else { return 0 }
        return weightKg / (hm * hm)
    }

    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    var bmr: Double {
        guard let a = age else { return 0 }
        // Mifflin-St Jeor
        let base = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(a))
        return biologicalSex == .male ? base + 5 : base - 161
    }

    var tdee: Double { bmr * activityLevel.tdeeMultiplier }

    // MARK: Init with defaults
    init(
        id: UUID = UUID(),
        appleUserId: String,
        email: String? = nil,
        fullName: String? = nil,
        avatarUrl: String? = nil,
        dateOfBirth: Date? = nil,
        biologicalSex: BiologicalSex = .other,
        heightCm: Double = 170,
        weightKg: Double = 70,
        targetWeightKg: Double? = nil,
        activityLevel: ActivityLevel = .moderatelyActive,
        goals: [HealthGoal] = [.generalHealth],
        dailyCalorieGoal: Double = Constants.Defaults.calorieGoal,
        dailyProteinGoal: Double = Constants.Defaults.proteinGoal,
        dailyCarbGoal: Double = Constants.Defaults.carbGoal,
        dailyFatGoal: Double = Constants.Defaults.fatGoal,
        dailyWaterGoal: Double = Constants.Defaults.waterGoal,
        dailyStepGoal: Int = Constants.Defaults.stepGoal,
        nightlySleepGoal: Double = Constants.Defaults.sleepGoal,
        weeklyWorkoutGoal: Int = 4,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.appleUserId = appleUserId
        self.email = email
        self.fullName = fullName
        self.avatarUrl = avatarUrl
        self.dateOfBirth = dateOfBirth
        self.biologicalSex = biologicalSex
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.targetWeightKg = targetWeightKg
        self.activityLevel = activityLevel
        self.goals = goals
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbGoal = dailyCarbGoal
        self.dailyFatGoal = dailyFatGoal
        self.dailyWaterGoal = dailyWaterGoal
        self.dailyStepGoal = dailyStepGoal
        self.nightlySleepGoal = nightlySleepGoal
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, email
        case appleUserId = "apple_user_id"
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case dateOfBirth = "date_of_birth"
        case biologicalSex = "biological_sex"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case targetWeightKg = "target_weight_kg"
        case activityLevel = "activity_level"
        case goals
        case dailyCalorieGoal = "daily_calorie_goal"
        case dailyProteinGoal = "daily_protein_goal"
        case dailyCarbGoal = "daily_carb_goal"
        case dailyFatGoal = "daily_fat_goal"
        case dailyWaterGoal = "daily_water_goal"
        case dailyStepGoal = "daily_step_goal"
        case nightlySleepGoal = "nightly_sleep_goal"
        case weeklyWorkoutGoal = "weekly_workout_goal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
