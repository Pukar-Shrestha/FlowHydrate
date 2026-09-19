import Foundation

/// Manages shared data between the main app and widget extension via App Groups UserDefaults.
///
/// All focus timer and hydration tracker state is persisted to a shared `UserDefaults` suite
/// so that widgets can read the latest values for display.
final class SharedDataManager: Sendable {
    /// The App Group suite name used for shared UserDefaults storage.
    static let suiteName = "group.com.flowhydrate.shared"

    /// Shared singleton instance.
    static let shared = SharedDataManager()

    /// The shared UserDefaults instance backed by the App Group container.
    private let defaults: UserDefaults?

    // MARK: - Keys

    /// Storage key for the number of seconds remaining in the current focus session.
    private let focusRemainingSecondsKey = "focus_remaining_seconds"

    /// Storage key for the total number of seconds in the current focus session.
    private let focusTotalSecondsKey = "focus_total_seconds"

    /// Storage key for the current focus session progress (0.0–1.0).
    private let focusProgressKey = "focus_progress"

    /// Storage key for the raw string value of the current timer mode.
    private let focusModeRawKey = "focus_mode_raw"

    /// Storage key for whether the focus timer is currently running.
    private let isFocusRunningKey = "is_focus_running"

    /// Storage key for the current water intake in milliliters.
    private let waterIntakeKey = "water_intake"

    /// Storage key for the daily water goal in milliliters.
    private let waterGoalKey = "water_goal"

    /// Storage key for the current hydration progress (0.0–1.0).
    private let waterProgressKey = "water_progress"

    // MARK: - Initialization

    private init() {
        defaults = UserDefaults(suiteName: Self.suiteName)
    }

    // MARK: - Focus Getters

    /// The number of seconds remaining in the current focus session.
    var focusRemainingSeconds: Int {
        defaults?.integer(forKey: focusRemainingSecondsKey) ?? 0
    }

    /// The total number of seconds in the current focus session.
    var focusTotalSeconds: Int {
        defaults?.integer(forKey: focusTotalSecondsKey) ?? 0
    }

    /// The current focus session progress as a value from 0.0 to 1.0.
    var focusProgress: Double {
        defaults?.double(forKey: focusProgressKey) ?? 0.0
    }

    /// The raw string value of the current timer mode (e.g., "focus", "shortBreak", "longBreak").
    var focusModeRaw: String {
        defaults?.string(forKey: focusModeRawKey) ?? "focus"
    }

    /// Whether the focus timer is currently running.
    var isFocusRunning: Bool {
        defaults?.bool(forKey: isFocusRunningKey) ?? false
    }

    // MARK: - Hydration Getters

    /// The current water intake in milliliters.
    var waterIntake: Double {
        defaults?.double(forKey: waterIntakeKey) ?? 0.0
    }

    /// The daily water goal in milliliters.
    var waterGoal: Double {
        let value = defaults?.double(forKey: waterGoalKey) ?? 0.0
        return value > 0 ? value : 2500.0
    }

    /// The current hydration progress as a value from 0.0 to 1.0.
    var waterProgress: Double {
        defaults?.double(forKey: waterProgressKey) ?? 0.0
    }

    // MARK: - Setters

    /// Updates all focus timer–related shared data at once.
    /// - Parameters:
    ///   - remaining: Seconds remaining in the session.
    ///   - total: Total seconds for the session.
    ///   - progress: Progress fraction from 0.0 to 1.0.
    ///   - mode: Raw string value of the current `TimerMode`.
    ///   - isRunning: Whether the timer is actively counting down.
    func updateFocus(remaining: Int, total: Int, progress: Double, mode: String, isRunning: Bool) {
        defaults?.set(remaining, forKey: focusRemainingSecondsKey)
        defaults?.set(total, forKey: focusTotalSecondsKey)
        defaults?.set(progress, forKey: focusProgressKey)
        defaults?.set(mode, forKey: focusModeRawKey)
        defaults?.set(isRunning, forKey: isFocusRunningKey)
        defaults?.synchronize()
    }

    /// Updates all hydration-related shared data at once.
    /// - Parameters:
    ///   - intake: Current water intake in milliliters.
    ///   - goal: Daily water goal in milliliters.
    func updateHydration(intake: Double, goal: Double) {
        let safeGoal = goal > 0 ? goal : 2500.0
        let progress = min(intake / safeGoal, 1.0)
        defaults?.set(intake, forKey: waterIntakeKey)
        defaults?.set(safeGoal, forKey: waterGoalKey)
        defaults?.set(progress, forKey: waterProgressKey)
        defaults?.synchronize()
    }
}
