import Foundation
import SwiftData

/// Provides sample data for SwiftUI previews and unit testing.
///
/// All data is deterministically generated relative to the current date,
/// ensuring previews always display recent, realistic content.
enum MockData {

    // MARK: - Calendar Helpers

    /// The shared calendar instance used for date calculations.
    private static let calendar = Calendar.current

    /// Returns the start of today.
    private static var today: Date {
        calendar.startOfDay(for: Date())
    }

    /// Returns a date offset from today by the given number of days.
    /// - Parameter days: Negative values go into the past.
    /// - Returns: The computed date at the start of the offset day.
    private static func date(daysAgo days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: today) ?? today
    }

    /// Returns a date at a specific hour on a given day offset.
    /// - Parameters:
    ///   - hour: The hour component (0–23).
    ///   - minute: The minute component (0–59).
    ///   - daysAgo: Number of days in the past.
    /// - Returns: The computed date.
    private static func date(hour: Int, minute: Int = 0, daysAgo: Int = 0) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date(daysAgo: daysAgo))
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? today
    }

    // MARK: - Focus Sessions

    /// Sample focus sessions spanning the last 7 days with varying durations and modes.
    ///
    /// Generates 3–5 sessions per day, alternating between focus and break modes
    /// to simulate realistic Pomodoro usage.
    static var focusSessions: [FocusSession] {
        var sessions: [FocusSession] = []

        // Day patterns: (daysAgo, [(hour, mode, duration, completed)])
        let patterns: [(Int, [(Int, TimerMode, TimeInterval, Bool)])] = [
            (0, [
                (9, .focus, 1500, true),
                (9, .shortBreak, 300, true),
                (10, .focus, 1500, true),
                (10, .shortBreak, 300, true),
                (11, .focus, 1500, false)
            ]),
            (1, [
                (8, .focus, 1500, true),
                (8, .shortBreak, 300, true),
                (9, .focus, 1500, true),
                (14, .focus, 1500, true),
                (14, .shortBreak, 300, true)
            ]),
            (2, [
                (10, .focus, 1500, true),
                (10, .shortBreak, 300, true),
                (11, .focus, 1500, true),
                (11, .shortBreak, 300, true),
                (12, .focus, 1500, true),
                (12, .longBreak, 900, true)
            ]),
            (3, [
                (9, .focus, 1500, true),
                (9, .shortBreak, 300, true),
                (10, .focus, 1500, true)
            ]),
            (4, [
                (13, .focus, 1500, true),
                (13, .shortBreak, 300, true),
                (14, .focus, 1500, true),
                (14, .shortBreak, 300, true),
                (15, .focus, 1500, true),
                (15, .longBreak, 900, true)
            ]),
            (5, [
                (8, .focus, 1500, true),
                (8, .shortBreak, 300, true),
                (9, .focus, 1500, true),
                (9, .shortBreak, 300, true)
            ]),
            (6, [
                (11, .focus, 1500, true),
                (11, .shortBreak, 300, true),
                (12, .focus, 1500, true),
                (16, .focus, 1500, true)
            ])
        ]

        for (daysAgo, dayEntries) in patterns {
            for (hour, mode, duration, completed) in dayEntries {
                let startDate = date(hour: hour, daysAgo: daysAgo)
                let session = FocusSession(mode: mode, duration: duration)
                session.startDate = startDate
                session.completed = completed
                if completed {
                    session.endDate = startDate.addingTimeInterval(duration)
                }
                sessions.append(session)
            }
        }

        return sessions
    }

    // MARK: - Water Logs

    /// Sample water log entries for today with realistic consumption patterns.
    ///
    /// Generates 8 entries throughout the day using common quick-add amounts.
    static var todayWaterLogs: [WaterLog] {
        let amounts: [(Int, Double)] = [
            (7, 250),   // Morning glass
            (8, 250),   // With breakfast
            (9, 100),   // Sip during commute
            (10, 500),  // Mid-morning bottle
            (12, 250),  // Lunch
            (14, 250),  // Afternoon
            (16, 500),  // Post-workout
            (18, 250)   // Dinner
        ]

        return amounts.map { hour, amount in
            let log = WaterLog(amount: amount)
            log.timestamp = date(hour: hour)
            return log
        }
    }

    // MARK: - Daily Records

    /// Sample daily records for the last 7 days with varying streak values.
    ///
    /// Simulates a user who has been consistently meeting their focus and hydration
    /// goals, building up streaks over the past week.
    static var dailyRecords: [DailyRecord] {
        (0...6).map { daysAgo in
            let record = DailyRecord()
            record.date = date(daysAgo: daysAgo)

            switch daysAgo {
            case 0:
                record.totalFocusMinutes = 50
                record.totalWaterIntake = 2350
                record.focusSessionsCompleted = 2
                record.focusStreak = 7
                record.hydrationStreak = 5
                record.combinedStreak = 5
                record.focusGoalMet = true
                record.hydrationGoalMet = false
            case 1:
                record.totalFocusMinutes = 75
                record.totalWaterIntake = 2600
                record.focusSessionsCompleted = 3
                record.focusStreak = 6
                record.hydrationStreak = 5
                record.combinedStreak = 5
                record.focusGoalMet = true
                record.hydrationGoalMet = true
            case 2:
                record.totalFocusMinutes = 100
                record.totalWaterIntake = 2800
                record.focusSessionsCompleted = 4
                record.focusStreak = 5
                record.hydrationStreak = 4
                record.combinedStreak = 4
                record.focusGoalMet = true
                record.hydrationGoalMet = true
            case 3:
                record.totalFocusMinutes = 50
                record.totalWaterIntake = 2500
                record.focusSessionsCompleted = 2
                record.focusStreak = 4
                record.hydrationStreak = 3
                record.combinedStreak = 3
                record.focusGoalMet = true
                record.hydrationGoalMet = true
            case 4:
                record.totalFocusMinutes = 75
                record.totalWaterIntake = 2700
                record.focusSessionsCompleted = 3
                record.focusStreak = 3
                record.hydrationStreak = 2
                record.combinedStreak = 2
                record.focusGoalMet = true
                record.hydrationGoalMet = true
            case 5:
                record.totalFocusMinutes = 50
                record.totalWaterIntake = 2400
                record.focusSessionsCompleted = 2
                record.focusStreak = 2
                record.hydrationStreak = 1
                record.combinedStreak = 1
                record.focusGoalMet = true
                record.hydrationGoalMet = false
            case 6:
                record.totalFocusMinutes = 75
                record.totalWaterIntake = 2900
                record.focusSessionsCompleted = 3
                record.focusStreak = 1
                record.hydrationStreak = 1
                record.combinedStreak = 1
                record.focusGoalMet = true
                record.hydrationGoalMet = true
            default:
                break
            }

            return record
        }
    }

    // MARK: - User Settings

    /// Default user settings suitable for previews and tests.
    static var settings: UserSettings {
        UserSettings()
    }

    // MARK: - Preview Container

    /// An in-memory ``ModelContainer`` pre-populated with sample data for SwiftUI previews.
    ///
    /// Usage in previews:
    /// ```swift
    /// #Preview {
    ///     SomeView()
    ///         .modelContainer(MockData.previewContainer)
    /// }
    /// ```
    @MainActor
    static var previewContainer: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            WaterLog.self,
            DailyRecord.self,
            UserSettings.self,
            configurations: config
        )
        let context = container.mainContext

        // Insert focus sessions
        for session in focusSessions {
            context.insert(session)
        }

        // Insert today's water logs
        for log in todayWaterLogs {
            context.insert(log)
        }

        // Insert daily records
        for record in dailyRecords {
            context.insert(record)
        }

        // Insert default settings
        context.insert(settings)

        try? context.save()

        return container
    }

    // MARK: - Chart Data

    /// Sample focus chart data points for a weekly view.
    ///
    /// Each point represents the total focus minutes for a day over the past 7 days.
    static var sampleFocusChartData: [ChartDataPoint] {
        let focusMinutes: [Double] = [75, 50, 75, 50, 100, 75, 50]
        return (0..<7).map { index in
            ChartDataPoint(
                date: date(daysAgo: 6 - index),
                value: focusMinutes[index]
            )
        }
    }

    /// Sample hydration chart data points for a weekly view.
    ///
    /// Each point represents the total water intake (mL) for a day over the past 7 days.
    static var sampleHydrationChartData: [ChartDataPoint] {
        let intakeValues: [Double] = [2900, 2400, 2700, 2500, 2800, 2600, 2350]
        return (0..<7).map { index in
            ChartDataPoint(
                date: date(daysAgo: 6 - index),
                value: intakeValues[index]
            )
        }
    }
}

// MARK: - Chart Data Point

/// A single data point for use with Swift Charts in the statistics view.
struct ChartDataPoint: Identifiable, Sendable {
    /// Unique identifier for the data point.
    let id = UUID()

    /// The date this data point represents.
    let date: Date

    /// The numeric value for this data point (minutes or milliliters).
    let value: Double
}
