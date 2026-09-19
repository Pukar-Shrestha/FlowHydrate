import Foundation
import SwiftData

/// Aggregated wellness data for a single calendar day.
///
/// Each day produces at most one `DailyRecord` that accumulates focus minutes,
/// water intake, session counts, and streak information.
@Model
final class DailyRecord {
    /// Unique identifier for this record
    var id: UUID = UUID()

    /// The calendar date this record represents, set to start of day
    var date: Date = Date()

    /// Total minutes spent in completed focus sessions
    var totalFocusMinutes: Double = 0

    /// Total water consumed in milliliters
    var totalWaterIntake: Double = 0

    /// Number of focus sessions completed
    var focusSessionsCompleted: Int = 0

    /// Current consecutive-day streak for meeting focus goals
    var focusStreak: Int = 0

    /// Current consecutive-day streak for meeting hydration goals
    var hydrationStreak: Int = 0

    /// Current consecutive-day streak for meeting both goals
    var combinedStreak: Int = 0

    /// Whether the daily focus goal was achieved
    var focusGoalMet: Bool = false

    /// Whether the daily hydration goal was achieved
    var hydrationGoalMet: Bool = false

    /// Creates a new daily record.
    /// - Parameter date: The calendar date, normalized to start of day.
    init(date: Date) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
    }

    /// Creates a `DailyRecord` for today with all counters at zero.
    /// - Returns: A fresh record with today's date.
    static func today() -> DailyRecord {
        DailyRecord(date: Date())
    }

    /// Whether this record represents the current calendar day.
    @Transient
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
