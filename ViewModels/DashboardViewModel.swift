import Foundation
import SwiftUI
import SwiftData

// MARK: - DashboardViewModel

/// Aggregates today's wellness metrics — focus minutes, completed sessions,
/// water intake, and streaks — for the main dashboard screen.
@Observable
final class DashboardViewModel {

    // MARK: - State

    /// Total focus minutes logged today.
    var todayFocusMinutes: Double = 0

    /// Number of completed focus sessions today.
    var todayFocusSessions: Int = 0

    /// Total water consumed today in millilitres.
    var todayWaterIntake: Double = 0

    /// The user's daily water goal in millilitres.
    var waterGoal: Double = 2500

    /// Consecutive days the focus goal has been met.
    var focusStreak: Int = 0

    /// Consecutive days the hydration goal has been met.
    var hydrationStreak: Int = 0

    /// Consecutive days both goals have been met.
    var combinedStreak: Int = 0

    // MARK: - Computed Properties

    /// A time-of-day greeting with a contextual wellness message.
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good evening"
        }
    }

    /// A short motivational subtitle based on today's progress.
    var subtitle: String {
        if todayFocusSessions == 0 && todayWaterIntake == 0 {
            return "Ready to start your day?"
        }
        if todayFocusSessions > 0 && todayWaterIntake >= waterGoal {
            return "Amazing work today! 🎉"
        }
        if todayFocusSessions > 0 {
            return "Keep the momentum going!"
        }
        if todayWaterIntake > 0 {
            return "Stay hydrated & focused!"
        }
        return "Let's get started!"
    }

    /// Formatted total focus time, e.g. "1h 25m" or "25m".
    var formattedFocusTime: String {
        let hours = Int(todayFocusMinutes) / 60
        let minutes = Int(todayFocusMinutes) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Formatted water intake in litres, e.g. "1.2 L".
    var formattedWaterIntake: String {
        let litres = todayWaterIntake / 1000
        return String(format: "%.1f L", litres)
    }

    /// Water progress as a value between 0 and 1.
    var waterProgress: Double {
        guard waterGoal > 0 else { return 0 }
        return min(max(todayWaterIntake / waterGoal, 0), 1)
    }

    /// Water progress as a formatted percentage string.
    var waterPercentageText: String {
        let pct = Int((waterProgress * 100).rounded())
        return "\(pct)%"
    }

    // MARK: - Data Loading

    /// Queries SwiftData for today's sessions, water logs, and streak records.
    ///
    /// - Parameter modelContext: SwiftData model context for querying.
    func loadData(modelContext: ModelContext) {
        loadTodayFocus(modelContext: modelContext)
        loadTodayWater(modelContext: modelContext)
        loadStreaks(modelContext: modelContext)
        loadWaterGoal(modelContext: modelContext)
    }

    // MARK: - Private Helpers

    /// Loads completed focus sessions recorded today.
    private func loadTodayFocus(modelContext: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { session in
                session.completed && session.startDate >= startOfDay && session.startDate < endOfDay
            }
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            todayFocusSessions = sessions.count
            todayFocusMinutes = sessions.reduce(0) { $0 + $1.duration } / 60.0
        } catch {
            todayFocusSessions = 0
            todayFocusMinutes = 0
        }
    }

    /// Loads water logs recorded today.
    private func loadTodayWater(modelContext: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let descriptor = FetchDescriptor<WaterLog>(
            predicate: #Predicate<WaterLog> { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay
            }
        )

        do {
            let logs = try modelContext.fetch(descriptor)
            todayWaterIntake = logs.reduce(0) { $0 + $1.amount }
        } catch {
            todayWaterIntake = 0
        }
    }

    /// Loads the most recent DailyRecord to surface streak information.
    private func loadStreaks(modelContext: ModelContext) {
        var descriptor = FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        do {
            if let latest = try modelContext.fetch(descriptor).first {
                focusStreak = latest.focusStreak
                hydrationStreak = latest.hydrationStreak
                combinedStreak = latest.combinedStreak
            }
        } catch {
            focusStreak = 0
            hydrationStreak = 0
            combinedStreak = 0
        }
    }

    /// Loads the user's water goal from settings.
    private func loadWaterGoal(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            if let settings = try modelContext.fetch(descriptor).first {
                waterGoal = settings.dailyWaterGoal
            }
        } catch {
            waterGoal = 2500
        }
    }
}
