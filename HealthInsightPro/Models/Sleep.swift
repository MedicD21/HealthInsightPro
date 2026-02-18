import Foundation

// MARK: - Sleep Stage
enum SleepStage: String, Codable, CaseIterable {
    case awake       = "awake"
    case remSleep    = "rem"
    case lightSleep  = "light"
    case deepSleep   = "deep"

    var displayName: String {
        switch self {
        case .awake:      return "Awake"
        case .remSleep:   return "REM"
        case .lightSleep: return "Light"
        case .deepSleep:  return "Deep"
        }
    }
    var color: String {
        switch self {
        case .awake:      return "#FF4F8B"
        case .remSleep:   return "#A855F7"
        case .lightSleep: return "#3B9EFF"
        case .deepSleep:  return "#1A3FAA"
        }
    }
    var icon: String {
        switch self {
        case .awake:      return "eye.fill"
        case .remSleep:   return "sparkles"
        case .lightSleep: return "moon.fill"
        case .deepSleep:  return "moon.zzz.fill"
        }
    }
}

// MARK: - Sleep Session
struct SleepEntry: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var startTime: Date
    var endTime: Date
    var stages: [SleepStageSegment]
    var source: String   // "healthkit", "manual", "garmin"
    var notes: String?

    // Heart rate during sleep
    var avgHeartRate: Double?
    var minHeartRate: Double?
    var maxHeartRate: Double?
    var avgHRV: Double?

    // Blood oxygen
    var avgOxygenSaturation: Double?   // %
    var minOxygenSaturation: Double?

    // Respiratory rate
    var avgRespiratoryRate: Double?

    // Calculated scores (0-100)
    var sleepScore: Int?
    var deepSleepScore: Int?
    var remSleepScore: Int?
    var efficiencyScore: Int?

    var createdAt: Date

    // MARK: Computed
    var totalDurationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
    var totalDurationHours: Double {
        endTime.timeIntervalSince(startTime) / 3600
    }
    var durationString: String {
        let h = totalDurationMinutes / 60
        let m = totalDurationMinutes % 60
        return "\(h)h \(m)m"
    }
    var efficiency: Double {
        let totalAwake = stages.filter { $0.stage == .awake }.reduce(0.0) { $0 + $1.durationMinutes }
        guard totalDurationMinutes > 0 else { return 0 }
        return 1.0 - (totalAwake / Double(totalDurationMinutes))
    }
    var deepSleepMinutes: Int {
        Int(stages.filter { $0.stage == .deepSleep }.reduce(0.0) { $0 + $1.durationMinutes })
    }
    var remSleepMinutes: Int {
        Int(stages.filter { $0.stage == .remSleep }.reduce(0.0) { $0 + $1.durationMinutes })
    }
    var lightSleepMinutes: Int {
        Int(stages.filter { $0.stage == .lightSleep }.reduce(0.0) { $0 + $1.durationMinutes })
    }

    var overallScore: Int {
        if let s = sleepScore { return s }
        // Compute a basic score if not provided
        var score = 0
        // Duration score (8h = full points)
        let durationFraction = min(1.0, totalDurationHours / 8.0)
        score += Int(durationFraction * 40)
        // Efficiency score
        score += Int(efficiency * 30)
        // Deep sleep (>1.5h ideal)
        let deepFraction = min(1.0, Double(deepSleepMinutes) / 90.0)
        score += Int(deepFraction * 20)
        // REM (>1.5h ideal)
        let remFraction = min(1.0, Double(remSleepMinutes) / 90.0)
        score += Int(remFraction * 10)
        return score
    }

    var scoreLabel: String {
        switch overallScore {
        case 80...100: return "Excellent"
        case 60...79:  return "Good"
        case 40...59:  return "Fair"
        default:       return "Poor"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, stages, source, notes
        case userId = "user_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case avgHeartRate = "avg_heart_rate"
        case minHeartRate = "min_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case avgHRV = "avg_hrv"
        case avgOxygenSaturation = "avg_oxygen_saturation"
        case minOxygenSaturation = "min_oxygen_saturation"
        case avgRespiratoryRate = "avg_respiratory_rate"
        case sleepScore = "sleep_score"
        case deepSleepScore = "deep_sleep_score"
        case remSleepScore = "rem_sleep_score"
        case efficiencyScore = "efficiency_score"
        case createdAt = "created_at"
    }
}

// MARK: - Sleep Stage Segment
struct SleepStageSegment: Codable, Identifiable {
    var id: UUID
    var stage: SleepStage
    var startTime: Date
    var durationMinutes: Double

    enum CodingKeys: String, CodingKey {
        case id, stage
        case startTime = "start_time"
        case durationMinutes = "duration_minutes"
    }
}

// MARK: - Sleep Habit
struct SleepHabit: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var date: Date
    var bedtimeGoal: Date?
    var wakeTimeGoal: Date?
    var caffeineConsumed: Bool
    var caffeineLastTime: Date?
    var alcoholConsumed: Bool
    var exerciseToday: Bool
    var screenTimeBeforeBed: Int?  // minutes
    var stressLevel: Int           // 1-10
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, date, notes
        case userId = "user_id"
        case bedtimeGoal = "bedtime_goal"
        case wakeTimeGoal = "wake_time_goal"
        case caffeineConsumed = "caffeine_consumed"
        case caffeineLastTime = "caffeine_last_time"
        case alcoholConsumed = "alcohol_consumed"
        case exerciseToday = "exercise_today"
        case screenTimeBeforeBed = "screen_time_before_bed"
        case stressLevel = "stress_level"
    }
}
