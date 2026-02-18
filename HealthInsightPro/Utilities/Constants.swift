import Foundation

// MARK: - Runtime Environment
enum AppEnvironment {
    enum Mode: String {
        case production
        case testing
    }

    private static func value(for key: String) -> String? {
        let envValue = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let envValue, !envValue.isEmpty {
            return envValue
        }

        let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String
        if let plistValue = plistValue?.trimmingCharacters(in: .whitespacesAndNewlines), !plistValue.isEmpty {
            return plistValue
        }

        return nil
    }

    private static func boolValue(for key: String, defaultValue: Bool) -> Bool {
        guard let raw = value(for: key)?.lowercased() else { return defaultValue }
        switch raw {
        case "1", "true", "yes", "y", "on":
            return true
        case "0", "false", "no", "n", "off":
            return false
        default:
            return defaultValue
        }
    }

    static var mode: Mode {
        #if DEBUG
        let configuredMode = value(for: "HIP_APP_MODE")?.lowercased()
        if configuredMode == Mode.production.rawValue {
            return .production
        }
        return .testing
        #else
        return .production
        #endif
    }

    static var isTesting: Bool { mode == .testing }

    static var modeLabel: String {
        isTesting ? "TEST MODE" : "PRODUCTION"
    }

    static var supabaseURLOverride: String? {
        guard isTesting else { return nil }
        return value(for: "HIP_SUPABASE_URL")
    }

    static var supabaseAnonKeyOverride: String? {
        guard isTesting else { return nil }
        return value(for: "HIP_SUPABASE_ANON_KEY")
    }

    static var bypassAppleSignIn: Bool {
        #if DEBUG
        guard isTesting else { return false }
        #if targetEnvironment(simulator)
        return boolValue(for: "HIP_BYPASS_APPLE_SIGN_IN", defaultValue: true)
        #else
        return boolValue(for: "HIP_BYPASS_APPLE_SIGN_IN", defaultValue: false)
        #endif
        #else
        return false
        #endif
    }
}

// MARK: - App Constants
enum Constants {

    // MARK: Supabase
    enum Supabase {
        private static let productionURL = "https://syrevcrnmcgxgevylhmy.supabase.co"
        private static let productionAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5cmV2Y3JubWNneGdldnlsaG15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0MjkwMDgsImV4cCI6MjA4NzAwNTAwOH0.FohsG8HpBS1-1IuBEb40KSh8afXauWI-defQ26-H8jU"

        static var url: String {
            AppEnvironment.supabaseURLOverride ?? productionURL
        }

        static var anonKey: String {
            AppEnvironment.supabaseAnonKeyOverride ?? productionAnonKey
        }
    }

    // MARK: App Info
    enum App {
        static let name    = "Health Insight Pro"
        static let version = "1.0.0"
        static let bundleId = "com.healthinsightpro.app"
    }

    // MARK: UserDefaults Keys
    enum Keys {
        static let onboardingComplete  = "onboardingComplete"
        static let userId              = "userId"
        static let userProfile         = "userProfile"
        static let weightUnit          = "weightUnit"       // "kg" or "lbs"
        static let heightUnit          = "heightUnit"       // "cm" or "ft"
        static let distanceUnit        = "distanceUnit"     // "km" or "mi"
        static let calorieGoal         = "calorieGoal"
        static let waterGoal           = "waterGoal"
        static let stepGoal            = "stepGoal"
        static let sleepGoal           = "sleepGoal"        // hours
        static let proteinGoal         = "proteinGoal"
        static let carbGoal            = "carbGoal"
        static let fatGoal             = "fatGoal"
        static let notificationsEnabled = "notificationsEnabled"
    }

    // MARK: Default Goals
    enum Defaults {
        static let calorieGoal: Double = 2000
        static let waterGoal: Double   = 2500   // ml
        static let stepGoal: Int       = 10000
        static let sleepGoal: Double   = 8.0    // hours
        static let proteinGoal: Double = 150    // g
        static let carbGoal: Double    = 250    // g
        static let fatGoal: Double     = 65     // g
    }

    // MARK: Nutrition
    enum Nutrition {
        static let caloriesPerGramProtein: Double = 4.0
        static let caloriesPerGramCarb: Double    = 4.0
        static let caloriesPerGramFat: Double     = 9.0
        static let caloriesPerGramAlcohol: Double = 7.0
    }

    // MARK: Score Ranges
    enum Scores {
        static let excellent: ClosedRange<Int> = 80...100
        static let good: ClosedRange<Int>      = 60...79
        static let fair: ClosedRange<Int>      = 40...59
        static let poor: ClosedRange<Int>      = 0...39
    }

    // MARK: Animation
    enum Animation {
        static let standard: Double = 0.35
        static let fast: Double     = 0.2
        static let slow: Double     = 0.6
    }

    // MARK: Layout
    enum Layout {
        static let padding: CGFloat     = 16
        static let paddingLg: CGFloat   = 24
        static let cornerRadius: CGFloat = 16
        static let cardSpacing: CGFloat  = 12
    }

    // MARK: Onboarding Pages
    enum Onboarding {
        static let totalSteps = 6
    }
}

// MARK: - Activity Levels
enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary       = "sedentary"
    case lightlyActive   = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive      = "very_active"
    case extraActive     = "extra_active"

    var displayName: String {
        switch self {
        case .sedentary:        return "Sedentary"
        case .lightlyActive:    return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive:       return "Very Active"
        case .extraActive:      return "Extra Active"
        }
    }
    var description: String {
        switch self {
        case .sedentary:        return "Little or no exercise"
        case .lightlyActive:    return "Exercise 1-3 days/week"
        case .moderatelyActive: return "Exercise 3-5 days/week"
        case .veryActive:       return "Hard exercise 6-7 days/week"
        case .extraActive:      return "Very hard exercise & physical job"
        }
    }
    var tdeeMultiplier: Double {
        switch self {
        case .sedentary:        return 1.2
        case .lightlyActive:    return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive:       return 1.725
        case .extraActive:      return 1.9
        }
    }
    var icon: String {
        switch self {
        case .sedentary:        return "figure.seated.seatbelt"
        case .lightlyActive:    return "figure.walk"
        case .moderatelyActive: return "figure.hiking"
        case .veryActive:       return "figure.run"
        case .extraActive:      return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Health Goals
enum HealthGoal: String, CaseIterable, Codable {
    case loseWeight   = "lose_weight"
    case maintainWeight = "maintain_weight"
    case gainMuscle   = "gain_muscle"
    case improveEnergy = "improve_energy"
    case betterSleep  = "better_sleep"
    case reduceStress = "reduce_stress"
    case generalHealth = "general_health"

    var displayName: String {
        switch self {
        case .loseWeight:     return "Lose Weight"
        case .maintainWeight: return "Maintain Weight"
        case .gainMuscle:     return "Gain Muscle"
        case .improveEnergy:  return "Improve Energy"
        case .betterSleep:    return "Better Sleep"
        case .reduceStress:   return "Reduce Stress"
        case .generalHealth:  return "General Health"
        }
    }
    var icon: String {
        switch self {
        case .loseWeight:     return "arrow.down.circle.fill"
        case .maintainWeight: return "equal.circle.fill"
        case .gainMuscle:     return "dumbbell.fill"
        case .improveEnergy:  return "bolt.fill"
        case .betterSleep:    return "moon.stars.fill"
        case .reduceStress:   return "heart.fill"
        case .generalHealth:  return "cross.case.fill"
        }
    }
}

// MARK: - Biological Sex
enum BiologicalSex: String, CaseIterable, Codable {
    case male   = "male"
    case female = "female"
    case other  = "other"

    var displayName: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        case .other:  return "Prefer not to say"
        }
    }
}
