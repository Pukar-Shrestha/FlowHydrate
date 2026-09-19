import Foundation
import SwiftUI
import SwiftData

// MARK: - HydrationViewModel

/// Manages daily water intake tracking, including logging, removal, HealthKit sync,
/// and widget updates.
@Observable
final class HydrationViewModel {

    // MARK: - State

    /// The total water consumed today in millilitres.
    var currentIntake: Double = 0

    /// The user's daily water goal in millilitres.
    var dailyGoal: Double = 2500

    /// All water logs recorded today, sorted by most recent first.
    var todayLogs: [WaterLog] = []

    // MARK: - Quick Add Presets

    /// Pre-defined quick-add amounts in millilitres.
    static let quickAmounts: [Double] = [100, 250, 500, 750]

    // MARK: - Computed Properties

    /// Progress toward the daily goal, clamped between 0 and 1.
    var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(max(currentIntake / dailyGoal, 0), 1)
    }

    /// Millilitres remaining to reach the daily goal. Never negative.
    var remainingIntake: Double {
        max(dailyGoal - currentIntake, 0)
    }

    /// Approximate number of 250 mL glasses consumed today.
    var glassesConsumed: Int {
        Int(currentIntake / 250)
    }

    /// Human-readable percentage string for the current progress.
    var percentageText: String {
        let pct = Int((progress * 100).rounded())
        return "\(pct)%"
    }

    // MARK: - Data Operations

    /// Records a new water intake entry and updates all derived state.
    ///
    /// - Parameters:
    ///   - amount: The volume consumed in millilitres.
    ///   - modelContext: SwiftData model context for persistence.
    func addWater(amount: Double, modelContext: ModelContext) {
        guard amount > 0 else { return }

        let log = WaterLog(
            id: UUID(),
            amount: amount,
            timestamp: Date()
        )
        modelContext.insert(log)
        try? modelContext.save()

        todayLogs.insert(log, at: 0)
        currentIntake += amount

        // Audio & haptic feedback.
        SoundService.shared.playWaterDrop()
        HapticService.shared.impact(.light)

        // HealthKit sync.
        syncToHealthKit(amount: amount)

        // Widget data.
        syncSharedData()
    }

    /// Fetches all water logs recorded today and recalculates the current intake.
    ///
    /// - Parameter modelContext: SwiftData model context for querying.
    func loadTodayData(modelContext: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let descriptor = FetchDescriptor<WaterLog>(
            predicate: #Predicate<WaterLog> { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            todayLogs = try modelContext.fetch(descriptor)
            currentIntake = todayLogs.reduce(0) { $0 + $1.amount }
        } catch {
            todayLogs = []
            currentIntake = 0
        }

        syncSharedData()
    }

    /// Removes a previously recorded water log (undo support).
    ///
    /// - Parameters:
    ///   - log: The `WaterLog` instance to delete.
    ///   - modelContext: SwiftData model context for persistence.
    func removeLog(_ log: WaterLog, modelContext: ModelContext) {
        modelContext.delete(log)
        try? modelContext.save()

        if let index = todayLogs.firstIndex(where: { $0.id == log.id }) {
            todayLogs.remove(at: index)
        }

        currentIntake = todayLogs.reduce(0) { $0 + $1.amount }

        HapticService.shared.notification(.warning)
        syncSharedData()
    }

    // MARK: - Private Helpers

    /// Asynchronously saves the intake to HealthKit when the feature is enabled.
    private func syncToHealthKit(amount: Double) {
        guard HealthKitService.shared.isAvailable else { return }

        Task { @MainActor in
            do {
                try await HealthKitService.shared.saveWaterIntake(amount: amount, date: Date())
            } catch {
                // HealthKit write failures are non-fatal; the local log is the source of truth.
            }
        }
    }

    /// Pushes the latest hydration state to the shared data store for widgets.
    private func syncSharedData() {
        SharedDataManager.shared.currentWaterIntake = currentIntake
        SharedDataManager.shared.dailyWaterGoal = dailyGoal
    }
}
