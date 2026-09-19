import Foundation
import SwiftUI
import SwiftData

// MARK: - SettingsViewModel

/// Wraps the persisted `UserSettings` model with load, save, and validation logic.
///
/// Properties mirror the `UserSettings` model and are clamped to safe ranges
/// before being persisted back.
@Observable
final class SettingsViewModel {

    // MARK: - Timer Durations (stored in seconds)

    /// Focus session duration in seconds.
    var focusDuration: Double = 1500

    /// Short break duration in seconds.
    var shortBreakDuration: Double = 300

    /// Long break duration in seconds.
    var longBreakDuration: Double = 900

    /// Whether the timer automatically starts the next session on completion.
    var autoStartNext: Bool = false

    // MARK: - Hydration

    /// Daily water intake goal in millilitres.
    var dailyWaterGoal: Double = 2500

    /// Interval between hydration reminders in seconds.
    var reminderInterval: Double = 3600

    /// The user's preferred volume unit.
    var volumeUnit: VolumeUnit = .milliliters

    // MARK: - Appearance

    /// The selected appearance mode (light / dark / system).
    var appearanceMode: AppearanceMode = .system

    // MARK: - Integrations

    /// Whether HealthKit integration is enabled.
    var healthKitEnabled: Bool = false

    /// Whether local notifications are enabled.
    var notificationsEnabled: Bool = false

    // MARK: - Internal Reference

    /// A reference to the persisted settings object, kept for updates.
    private var settingsModel: UserSettings?

    // MARK: - Computed Display Strings

    /// Focus duration formatted as a human-readable string, e.g. "25 min".
    var formattedFocusDuration: String {
        formatMinutes(focusDuration)
    }

    /// Short break duration formatted as a human-readable string, e.g. "5 min".
    var formattedShortBreakDuration: String {
        formatMinutes(shortBreakDuration)
    }

    /// Long break duration formatted as a human-readable string, e.g. "15 min".
    var formattedLongBreakDuration: String {
        formatMinutes(longBreakDuration)
    }

    /// Daily water goal formatted in litres, e.g. "2.5 L".
    var formattedDailyWaterGoal: String {
        String(format: "%.1f L", dailyWaterGoal / 1000)
    }

    /// Reminder interval formatted in minutes, e.g. "60 min".
    var formattedReminderInterval: String {
        formatMinutes(reminderInterval)
    }

    // MARK: - Load

    /// Fetches the first `UserSettings` from the store, or creates a default instance.
    ///
    /// - Parameter modelContext: SwiftData model context for querying and inserting.
    func loadSettings(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            if let existing = try modelContext.fetch(descriptor).first {
                settingsModel = existing
                populateFromModel(existing)
            } else {
                let defaults = UserSettings()
                modelContext.insert(defaults)
                try? modelContext.save()
                settingsModel = defaults
                populateFromModel(defaults)
            }
        } catch {
            let defaults = UserSettings()
            modelContext.insert(defaults)
            try? modelContext.save()
            settingsModel = defaults
            populateFromModel(defaults)
        }
    }

    // MARK: - Save

    /// Validates and persists the current property values back to the `UserSettings` model.
    ///
    /// - Parameter modelContext: SwiftData model context for saving.
    func save(modelContext: ModelContext) {
        clampValues()

        guard let model = settingsModel else { return }

        model.focusDuration = focusDuration
        model.shortBreakDuration = shortBreakDuration
        model.longBreakDuration = longBreakDuration
        model.autoStartNext = autoStartNext
        model.dailyWaterGoal = dailyWaterGoal
        model.reminderInterval = reminderInterval
        model.volumeUnit = volumeUnit
        model.appearanceMode = appearanceMode
        model.healthKitEnabled = healthKitEnabled
        model.notificationsEnabled = notificationsEnabled

        try? modelContext.save()

        // Update widget shared data with the new goal.
        SharedDataManager.shared.dailyWaterGoal = dailyWaterGoal
    }

    // MARK: - Validation

    /// Clamps all duration and goal values to their allowed ranges.
    ///
    /// - Focus duration: 1 – 120 minutes (60 – 7200 seconds)
    /// - Break durations: 1 – 60 minutes (60 – 3600 seconds)
    /// - Daily water goal: 500 – 10 000 mL
    /// - Reminder interval: 5 – 240 minutes (300 – 14400 seconds)
    private func clampValues() {
        focusDuration = min(max(focusDuration, 60), 7200)
        shortBreakDuration = min(max(shortBreakDuration, 60), 3600)
        longBreakDuration = min(max(longBreakDuration, 60), 3600)
        dailyWaterGoal = min(max(dailyWaterGoal, 500), 10000)
        reminderInterval = min(max(reminderInterval, 300), 14400)
    }

    // MARK: - Private Helpers

    /// Copies the model's values into this view model's properties.
    private func populateFromModel(_ model: UserSettings) {
        focusDuration = model.focusDuration
        shortBreakDuration = model.shortBreakDuration
        longBreakDuration = model.longBreakDuration
        autoStartNext = model.autoStartNext
        dailyWaterGoal = model.dailyWaterGoal
        reminderInterval = model.reminderInterval
        volumeUnit = model.volumeUnit
        appearanceMode = model.appearanceMode
        healthKitEnabled = model.healthKitEnabled
        notificationsEnabled = model.notificationsEnabled
    }

    /// Converts a duration in seconds to a formatted string like "25 min" or "1 hr 30 min".
    private func formatMinutes(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours) hr \(minutes) min"
        } else if hours > 0 {
            return "\(hours) hr"
        }
        return "\(minutes) min"
    }
}
