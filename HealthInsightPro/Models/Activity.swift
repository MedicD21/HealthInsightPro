import Foundation

// MARK: - Activity Type
enum ActivityType: String, CaseIterable, Codable {
    case running      = "running"
    case walking      = "walking"
    case cycling      = "cycling"
    case swimming     = "swimming"
    case weightlifting = "weightlifting"
    case yoga         = "yoga"
    case hiit         = "hiit"
    case basketball   = "basketball"
    case soccer       = "soccer"
    case tennis       = "tennis"
    case hiking       = "hiking"
    case rowing       = "rowing"
    case pilates      = "pilates"
    case dancing      = "dancing"
    case other        = "other"

    var displayName: String {
        switch self {
        case .running:       return "Running"
        case .walking:       return "Walking"
        case .cycling:       return "Cycling"
        case .swimming:      return "Swimming"
        case .weightlifting: return "Weight Training"
        case .yoga:          return "Yoga"
        case .hiit:          return "HIIT"
        case .basketball:    return "Basketball"
        case .soccer:        return "Soccer"
        case .tennis:        return "Tennis"
        case .hiking:        return "Hiking"
        case .rowing:        return "Rowing"
        case .pilates:       return "Pilates"
        case .dancing:       return "Dancing"
        case .other:         return "Other"
        }
    }
    var icon: String {
        switch self {
        case .running:       return "figure.run"
        case .walking:       return "figure.walk"
        case .cycling:       return "figure.outdoor.cycle"
        case .swimming:      return "figure.pool.swim"
        case .weightlifting: return "figure.strengthtraining.traditional"
        case .yoga:          return "figure.yoga"
        case .hiit:          return "bolt.fill"
        case .basketball:    return "basketball.fill"
        case .soccer:        return "soccerball"
        case .tennis:        return "tennisball.fill"
        case .hiking:        return "figure.hiking"
        case .rowing:        return "figure.rowing"
        case .pilates:       return "figure.pilates"
        case .dancing:       return "figure.dance"
        case .other:         return "figure.mixed.cardio"
        }
    }
    // MET values (rough average)
    var metValue: Double {
        switch self {
        case .running:       return 9.8
        case .walking:       return 3.5
        case .cycling:       return 7.5
        case .swimming:      return 7.0
        case .weightlifting: return 5.0
        case .yoga:          return 3.0
        case .hiit:          return 10.0
        case .basketball:    return 8.0
        case .soccer:        return 7.0
        case .tennis:        return 7.3
        case .hiking:        return 5.3
        case .rowing:        return 7.0
        case .pilates:       return 3.5
        case .dancing:       return 5.0
        case .other:         return 5.0
        }
    }
}

// MARK: - Workout / Activity Entry
struct ActivityEntry: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var activityType: ActivityType
    var name: String?
    var startTime: Date
    var endTime: Date
    var durationMinutes: Double
    var caloriesBurned: Double
    var distanceKm: Double?
    var avgHeartRate: Double?
    var maxHeartRate: Double?
    var steps: Int?
    var elevationGainM: Double?
    var avgPaceMinPerKm: Double?
    var avgCadence: Double?
    var avgPower: Double?       // watts (cycling)
    var vo2max: Double?
    var strainScore: Int?       // 0-100
    var source: String          // "healthkit", "manual", "garmin"
    var notes: String?
    var route: [[Double]]?      // [[lat, lng]] for GPS track
    var createdAt: Date

    // Computed calories from MET if not provided
    var estimatedCalories: Double {
        if caloriesBurned > 0 { return caloriesBurned }
        // Cal = MET * weight_kg * hours
        return activityType.metValue * 70.0 * (durationMinutes / 60.0)
    }

    var distanceString: String? {
        guard let d = distanceKm else { return nil }
        let miles = ImperialUnits.kmToMiles(d)
        if miles >= 0.1 {
            return String(format: "%.2f mi", miles)
        }
        return String(format: "%.0f ft", ImperialUnits.kmToFeet(d))
    }

    enum CodingKeys: String, CodingKey {
        case id, name, source, notes, route
        case userId = "user_id"
        case activityType = "activity_type"
        case startTime = "start_time"
        case endTime = "end_time"
        case durationMinutes = "duration_minutes"
        case caloriesBurned = "calories_burned"
        case distanceKm = "distance_km"
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case steps
        case elevationGainM = "elevation_gain_m"
        case avgPaceMinPerKm = "avg_pace_min_per_km"
        case avgCadence = "avg_cadence"
        case avgPower = "avg_power"
        case vo2max
        case strainScore = "strain_score"
        case createdAt = "created_at"
    }
}

// MARK: - Daily Activity Summary
struct DailyActivity: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var date: Date
    var steps: Int
    var distanceKm: Double
    var activeCalories: Double
    var restingCalories: Double
    var totalCalories: Double
    var activeMinutes: Int
    var standingHours: Int
    var avgHeartRate: Double?
    var restingHeartRate: Double?
    var maxHeartRate: Double?
    var vo2max: Double?

    var totalCaloriesBurned: Double { activeCalories + restingCalories }

    enum CodingKeys: String, CodingKey {
        case id, date, steps
        case userId = "user_id"
        case distanceKm = "distance_km"
        case activeCalories = "active_calories"
        case restingCalories = "resting_calories"
        case totalCalories = "total_calories"
        case activeMinutes = "active_minutes"
        case standingHours = "standing_hours"
        case avgHeartRate = "avg_heart_rate"
        case restingHeartRate = "resting_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case vo2max
    }
}

// MARK: - TDEE Breakdown
struct TDEEBreakdown {
    var bmr: Double      // Basal Metabolic Rate
    var neat: Double     // Non-Exercise Activity Thermogenesis (steps, fidgeting)
    var tef: Double      // Thermic Effect of Food (~10% of calories consumed)
    var eat: Double      // Exercise Activity Thermogenesis (workouts)

    var total: Double { bmr + neat + tef + eat }

    static func calculate(profile: UserProfile, dailyActivity: DailyActivity?, caloriesConsumed: Double) -> TDEEBreakdown {
        let bmr = profile.bmr
        let neat = dailyActivity.map { Double($0.steps) * 0.04 } ?? 0  // ~0.04 cal/step
        let tef = caloriesConsumed * 0.10
        let eat = dailyActivity?.activeCalories ?? 0

        return TDEEBreakdown(bmr: bmr, neat: neat, tef: tef, eat: eat)
    }
}

// MARK: - Heart Rate Entry
struct HeartRateEntry: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var bpm: Double
    var recordedAt: Date
    var context: String?  // "resting", "active", "sleeping", "workout"

    var zone: HeartRateZone { HeartRateZone.zone(for: bpm) }

    enum CodingKeys: String, CodingKey {
        case id, bpm, context
        case userId = "user_id"
        case recordedAt = "recorded_at"
    }
}

enum HeartRateZone: String {
    case zone1 = "Zone 1 - Recovery"
    case zone2 = "Zone 2 - Aerobic"
    case zone3 = "Zone 3 - Tempo"
    case zone4 = "Zone 4 - Threshold"
    case zone5 = "Zone 5 - Max"

    static func zone(for bpm: Double) -> HeartRateZone {
        switch bpm {
        case ..<100: return .zone1
        case 100..<120: return .zone2
        case 120..<140: return .zone3
        case 140..<160: return .zone4
        default: return .zone5
        }
    }

    var color: String {
        switch self {
        case .zone1: return "#3B9EFF"
        case .zone2: return "#00E5A0"
        case .zone3: return "#FFD23F"
        case .zone4: return "#FF7A3B"
        case .zone5: return "#FF4F8B"
        }
    }
}
