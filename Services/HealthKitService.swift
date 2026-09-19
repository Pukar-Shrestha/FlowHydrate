import Foundation
import HealthKit

/// Actor-isolated HealthKit integration for reading and writing water intake data.
///
/// All HealthKit operations are isolated to this actor to satisfy Swift 6 concurrency
/// requirements. Gracefully handles environments where HealthKit is unavailable
/// (e.g., iPad, Simulator without HealthKit capability).
actor HealthKitService {
    /// Shared singleton instance
    static let shared = HealthKitService()

    /// The HealthKit store used for all read/write operations
    private let healthStore: HKHealthStore?

    /// The quantity type representing dietary water intake
    private let waterType = HKQuantityType(.dietaryWater)

    /// The unit used for water measurements (milliliters)
    private let mlUnit = HKUnit.literUnit(with: .milli)

    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
        }
    }

    /// Whether HealthKit data is available on this device.
    var isAvailable: Bool {
        healthStore != nil
    }

    /// Requests read and write authorization for dietary water data.
    ///
    /// - Throws: An error if the authorization request fails or HealthKit is unavailable.
    func requestAuthorization() async throws {
        guard let healthStore else {
            throw HealthKitServiceError.unavailable
        }

        let typesToShare: Set<HKSampleType> = [waterType]
        let typesToRead: Set<HKObjectType> = [waterType]

        try await healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        )
    }

    /// Saves a water intake sample to HealthKit.
    ///
    /// - Parameters:
    ///   - amount: Volume of water consumed in milliliters.
    ///   - date: When the water was consumed.
    /// - Throws: An error if the save fails or HealthKit is unavailable.
    func saveWaterIntake(amount: Double, date: Date) async throws {
        guard let healthStore else {
            throw HealthKitServiceError.unavailable
        }

        let quantity = HKQuantity(unit: mlUnit, doubleValue: amount)
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: date,
            end: date
        )

        try await healthStore.save(sample)
    }

    /// Reads the total water intake for today from HealthKit.
    ///
    /// - Returns: Total water consumed today in milliliters.
    /// - Throws: An error if the query fails or HealthKit is unavailable.
    func readTodayWaterIntake() async throws -> Double {
        guard let healthStore else {
            throw HealthKitServiceError.unavailable
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: waterType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let total = statistics?
                    .sumQuantity()?
                    .doubleValue(for: HKUnit.literUnit(with: .milli)) ?? 0

                continuation.resume(returning: total)
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Errors

/// Errors specific to the HealthKit service.
enum HealthKitServiceError: LocalizedError {
    /// HealthKit is not available on this device
    case unavailable

    /// Human-readable description of the error
    var errorDescription: String? {
        switch self {
        case .unavailable:
            "HealthKit is not available on this device."
        }
    }
}
