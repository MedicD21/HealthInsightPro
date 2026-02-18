import Foundation

// MARK: - Water / Hydration
struct WaterEntry: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var amountMl: Double
    var loggedAt: Date
    var containerType: WaterContainerType?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amountMl = "amount_ml"
        case loggedAt = "logged_at"
        case containerType = "container_type"
    }
}

enum WaterContainerType: String, CaseIterable, Codable {
    case smallGlass  = "small_glass"   // 150ml
    case glass       = "glass"         // 250ml
    case largeGlass  = "large_glass"   // 350ml
    case bottle      = "bottle"        // 500ml
    case largeBottle = "large_bottle"  // 750ml
    case xlBottle    = "xl_bottle"     // 1000ml
    case custom      = "custom"

    var ml: Double {
        switch self {
        case .smallGlass:  return 150
        case .glass:       return 250
        case .largeGlass:  return 350
        case .bottle:      return 500
        case .largeBottle: return 750
        case .xlBottle:    return 1000
        case .custom:      return 250
        }
    }
    var displayName: String {
        switch self {
        case .smallGlass:  return "Small Glass"
        case .glass:       return "Glass"
        case .largeGlass:  return "Large Glass"
        case .bottle:      return "Bottle"
        case .largeBottle: return "Large Bottle"
        case .xlBottle:    return "Water Jug"
        case .custom:      return "Custom"
        }
    }
    var icon: String { "drop.fill" }
}

// MARK: - Weight Entry
struct WeightEntry: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var weightKg: Double
    var bodyFatPercent: Double?
    var muscleMassKg: Double?
    var boneMassKg: Double?
    var waterPercent: Double?
    var bmi: Double?
    var visceralFat: Double?
    var loggedAt: Date
    var notes: String?
    var source: String  // "manual", "scale"

    enum CodingKeys: String, CodingKey {
        case id, notes, source
        case userId = "user_id"
        case weightKg = "weight_kg"
        case bodyFatPercent = "body_fat_percent"
        case muscleMassKg = "muscle_mass_kg"
        case boneMassKg = "bone_mass_kg"
        case waterPercent = "water_percent"
        case bmi
        case visceralFat = "visceral_fat"
        case loggedAt = "logged_at"
    }
}

// MARK: - Insight / Score
struct InsightScores: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var date: Date

    var recoveryScore: Int    // 0-100
    var stressScore: Int      // 0-100
    var strainScore: Int      // 0-100 (how hard the day was)
    var readinessScore: Int   // 0-100 (ready to train?)
    var sleepScore: Int       // 0-100
    var nutritionScore: Int   // 0-100
    var hydrationScore: Int   // 0-100

    var overallWellnessScore: Int {
        (recoveryScore + sleepScore + nutritionScore + hydrationScore) / 4
    }

    var recoveryLabel: String { scoreLabel(recoveryScore) }
    var stressLabel: String { scoreLabel(stressScore) }

    private func scoreLabel(_ score: Int) -> String {
        switch score {
        case 80...100: return "Excellent"
        case 60...79:  return "Good"
        case 40...59:  return "Fair"
        default:       return "Poor"
        }
    }

    static func compute(
        sleep: SleepEntry?,
        nutrition: NutritionDaySummary?,
        activity: DailyActivity?,
        water: Double,
        waterGoal: Double
    ) -> InsightScores {
        let sleepScore = sleep.map { $0.overallScore } ?? 50
        let nutritionScore = nutrition.map { Int($0.calorieProgress * 100) } ?? 50
        let hydrationScore = Int(min(1.0, water / max(1, waterGoal)) * 100)

        let activityScore: Int
        if let a = activity {
            let stepFraction = min(1.0, Double(a.steps) / 10000.0)
            activityScore = Int(stepFraction * 100)
        } else {
            activityScore = 30
        }

        let recoveryScore = (sleepScore + 100 - activityScore) / 2
        let stressScore = max(0, 100 - activityScore)
        let strainScore = activityScore

        return InsightScores(
            id: UUID(),
            userId: UUID(),  // will be overridden
            date: Date(),
            recoveryScore: recoveryScore.clamped(min: 0, max: 100),
            stressScore: stressScore.clamped(min: 0, max: 100),
            strainScore: strainScore.clamped(min: 0, max: 100),
            readinessScore: recoveryScore.clamped(min: 0, max: 100),
            sleepScore: sleepScore,
            nutritionScore: nutritionScore,
            hydrationScore: hydrationScore
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, date
        case userId = "user_id"
        case recoveryScore = "recovery_score"
        case stressScore = "stress_score"
        case strainScore = "strain_score"
        case readinessScore = "readiness_score"
        case sleepScore = "sleep_score"
        case nutritionScore = "nutrition_score"
        case hydrationScore = "hydration_score"
    }
}

extension Int {
    func clamped(min minVal: Int, max maxVal: Int) -> Int {
        Swift.min(maxVal, Swift.max(minVal, self))
    }
}

// MARK: - Health Journal Entry
struct JournalEntry: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var date: Date
    var mood: MoodLevel
    var energyLevel: Int     // 1-10
    var stressLevel: Int     // 1-10
    var anxietyLevel: Int    // 1-10
    var notes: String?

    // Habits tracked
    var meditatedToday: Bool
    var exercisedToday: Bool
    var alcoholConsumed: Bool
    var alcoholServings: Int?
    var smokingToday: Bool
    var medicationTaken: Bool
    var medicationNotes: String?
    var sunlightExposureMinutes: Int?
    var socialInteraction: Bool
    var gratitudeNotes: String?
    var symptomsReported: [String]
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case id, date, mood, notes, tags
        case userId = "user_id"
        case energyLevel = "energy_level"
        case stressLevel = "stress_level"
        case anxietyLevel = "anxiety_level"
        case meditatedToday = "meditated_today"
        case exercisedToday = "exercised_today"
        case alcoholConsumed = "alcohol_consumed"
        case alcoholServings = "alcohol_servings"
        case smokingToday = "smoking_today"
        case medicationTaken = "medication_taken"
        case medicationNotes = "medication_notes"
        case sunlightExposureMinutes = "sunlight_exposure_minutes"
        case socialInteraction = "social_interaction"
        case gratitudeNotes = "gratitude_notes"
        case symptomsReported = "symptoms_reported"
    }
}

enum MoodLevel: String, CaseIterable, Codable {
    case awful     = "awful"
    case bad       = "bad"
    case okay      = "okay"
    case good      = "good"
    case great     = "great"
    case excellent = "excellent"

    var displayName: String { rawValue.capitalized }
    var emoji: String {
        switch self {
        case .awful:     return "😞"
        case .bad:       return "😕"
        case .okay:      return "😐"
        case .good:      return "🙂"
        case .great:     return "😊"
        case .excellent: return "😁"
        }
    }
    var score: Int {
        switch self {
        case .awful: return 1; case .bad: return 2; case .okay: return 3
        case .good: return 4; case .great: return 5; case .excellent: return 6
        }
    }
    var color: String {
        switch self {
        case .awful, .bad:     return "#FF4F8B"
        case .okay:            return "#FFD23F"
        case .good, .great:    return "#00E5A0"
        case .excellent:       return "#6C63FF"
        }
    }
}

// MARK: - Blood Metrics
struct BloodMetric: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var recordedAt: Date
    var oxygenSaturation: Double?   // %
    var respiratoryRate: Double?    // breaths/min
    var systolicBP: Double?         // mmHg
    var diastolicBP: Double?        // mmHg
    var bloodGlucose: Double?       // mg/dL
    var heartRateVariability: Double? // ms

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recordedAt = "recorded_at"
        case oxygenSaturation = "oxygen_saturation"
        case respiratoryRate = "respiratory_rate"
        case systolicBP = "systolic_bp"
        case diastolicBP = "diastolic_bp"
        case bloodGlucose = "blood_glucose"
        case heartRateVariability = "hrv"
    }
}
