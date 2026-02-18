import Foundation
import HealthKit

// MARK: - HealthKit Service
@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined

    // MARK: - Types to read
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .distanceWalkingRunning,
            .distanceCycling,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .heartRate,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .oxygenSaturation,
            .respiratoryRate,
            .bodyMass,
            .bodyFatPercentage,
            .leanBodyMass,
            .bodyMassIndex,
            .height,
            .dietaryEnergyConsumed,
            .dietaryProtein,
            .dietaryCarbohydrates,
            .dietaryFatTotal,
            .dietaryWater,
            .vo2Max,
            .walkingHeartRateAverage,
            .sixMinuteWalkTestDistance,
            .flightsClimbed
        ]
        for id in quantityTypes {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        if let workout = HKObjectType.workoutType() as? HKObjectType { types.insert(workout) }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) { types.insert(mindful) }
        return types
    }()

    // MARK: - Types to write
    private let writeTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .bodyMass,
            .dietaryEnergyConsumed,
            .dietaryProtein,
            .dietaryCarbohydrates,
            .dietaryFatTotal,
            .dietaryWater
        ]
        for id in quantityTypes {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let workout = HKObjectType.workoutType() as? HKSampleType { types.insert(workout) }
        return types
    }()

    private init() {}

    // MARK: - Request Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    // MARK: - Steps
    func fetchStepsToday() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let start = Date().startOfDay
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(value))
            }
            store.execute(query)
        }
    }

    func fetchSteps(days: Int) async -> [(Date, Int)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }
        let start = Date().daysAgo(days).startOfDay
        return await fetchDailyQuantity(type: type, start: start, unit: .count(), aggregation: .cumulativeSum)
            .map { ($0.0, Int($0.1)) }
    }

    // MARK: - Calories
    func fetchActiveCaloriesToday() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let start = Date().startOfDay
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    func fetchRestingCaloriesToday() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return 0 }
        let start = Date().startOfDay
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Heart Rate
    func fetchRestingHeartRate() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        let start = Date().daysAgo(1)
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .discreteAverage) { _, stats, _ in
                let value = stats?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    func fetchHeartRateVariability() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }
        let start = Date().daysAgo(1)
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .discreteAverage) { _, stats, _ in
                let value = stats?.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli))
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Sleep
    func fetchSleepLastNight() async -> SleepEntry? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let start = Date().daysAgo(1)
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let start = samples.first!.startDate
                let end = samples.last!.endDate
                var stages: [SleepStageSegment] = []

                for sample in samples {
                    let stage: SleepStage
                    switch HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                    case .awake, .inBed:          stage = .awake
                    case .asleepREM:              stage = .remSleep
                    case .asleepCore, .asleepUnspecified: stage = .lightSleep
                    case .asleepDeep:             stage = .deepSleep
                    default:                      stage = .lightSleep
                    }
                    let dur = sample.endDate.timeIntervalSince(sample.startDate) / 60
                    stages.append(SleepStageSegment(id: UUID(), stage: stage, startTime: sample.startDate, durationMinutes: dur))
                }

                let entry = SleepEntry(
                    id: UUID(), userId: UUID(),
                    startTime: start, endTime: end,
                    stages: stages, source: "healthkit",
                    createdAt: Date()
                )
                continuation.resume(returning: entry)
            }
            self.store.execute(query)
        }
    }

    // MARK: - Body Mass
    func fetchLatestWeight() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        return await fetchLatestQuantity(type: type, unit: .gramUnit(with: .kilo))
    }

    func saveWeight(kg: Double) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let qty = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: qty, start: Date(), end: Date())
        try await store.save(sample)
    }

    // MARK: - VO2Max
    func fetchVO2Max() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return nil }
        let unit = HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        return await fetchLatestQuantity(type: type, unit: unit)
    }

    // MARK: - Distance
    func fetchDistanceToday() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }
        let start = Date().startOfDay
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Workouts
    func fetchWorkouts(days: Int = 7) async -> [ActivityEntry] {
        let start = Date().daysAgo(days)
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: pred, limit: 50, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }

                let entries: [ActivityEntry] = workouts.map { w in
                    let actType = Self.mapWorkoutType(w.workoutActivityType)
                    return ActivityEntry(
                        id: UUID(),
                        userId: UUID(),
                        activityType: actType,
                        startTime: w.startDate,
                        endTime: w.endDate,
                        durationMinutes: w.duration / 60,
                        caloriesBurned: w.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        distanceKm: w.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)),
                        source: "healthkit",
                        createdAt: Date()
                    )
                }
                continuation.resume(returning: entries)
            }
            self.store.execute(query)
        }
    }

    // MARK: - Helpers
    private func fetchLatestQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        let pred = HKQuery.predicateForSamples(withStart: Date().daysAgo(30), end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: pred, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchDailyQuantity(type: HKQuantityType, start: Date, unit: HKUnit, aggregation: HKStatisticsOptions) async -> [(Date, Double)] {
        let interval = DateComponents(day: 1)
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: pred, options: aggregation, anchorDate: start.startOfDay, intervalComponents: interval)
            query.initialResultsHandler = { _, results, _ in
                var data: [(Date, Double)] = []
                results?.enumerateStatistics(from: start, to: Date()) { stats, _ in
                    let val: Double
                    if aggregation == .cumulativeSum {
                        val = stats.sumQuantity()?.doubleValue(for: unit) ?? 0
                    } else {
                        val = stats.averageQuantity()?.doubleValue(for: unit) ?? 0
                    }
                    data.append((stats.startDate, val))
                }
                continuation.resume(returning: data)
            }
            store.execute(query)
        }
    }

    private static func mapWorkoutType(_ type: HKWorkoutActivityType) -> ActivityType {
        switch type {
        case .running:          return .running
        case .walking:          return .walking
        case .cycling:          return .cycling
        case .swimming:         return .swimming
        case .functionalStrengthTraining, .traditionalStrengthTraining: return .weightlifting
        case .yoga:             return .yoga
        case .highIntensityIntervalTraining: return .hiit
        case .basketball:       return .basketball
        case .soccer:           return .soccer
        case .tennis:           return .tennis
        case .hiking:           return .hiking
        case .rowing:           return .rowing
        case .pilates:          return .pilates
        case .dance:            return .dancing
        default:                return .other
        }
    }
}
