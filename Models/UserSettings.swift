import Foundation
import SwiftData

/// Persisted user preferences for the FlowHydrate app.
///
/// Designed as a singleton — only one instance should exist in the SwiftData store.
/// Enum-backed settings use raw-value strings for SwiftData compatibility with
/// transient computed wrappers for type-safe access.
@Model
final class UserSettings {
    /// Unique identifier for this settings record
    var id: UUID = UUID()

    /// Focus session duration in seconds
    var focusDuration: Double = 1500

    /// Short break duration in seconds
    var shortBreakDuration: Double = 300

    /// Long break duration in seconds
    var longBreakDuration: Double = 900

    /// Whether to auto-start the next timer phase after one completes
    var autoStartNext: Bool = false

    /// Daily water intake goal in milliliters
    var dailyWaterGoal: Double = 2500

    /// Interval in seconds between hydration reminders
    var reminderInterval: Double = 3600

    /// Raw string backing for the volume unit preference
    var volumeUnitRawValue: String = VolumeUnit.milliliters.rawValue

    /// Raw string backing for the appearance mode preference
    var appearanceModeRawValue: String = AppearanceMode.system.rawValue

    /// Whether HealthKit integration is enabled
    var healthKitEnabled: Bool = false

    /// Whether local notifications are enabled
    var notificationsEnabled: Bool = true

    // MARK: - Transient Computed Properties

    /// The user's preferred volume display unit.
    @Transient
    var volumeUnit: VolumeUnit {
        get { VolumeUnit(rawValue: volumeUnitRawValue) ?? .milliliters }
        set { volumeUnitRawValue = newValue.rawValue }
    }

    /// The user's preferred app appearance.
    @Transient
    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRawValue) ?? .system }
        set { appearanceModeRawValue = newValue.rawValue }
    }

    /// Creates a new settings record with all default values.
    init() {
        self.id = UUID()
    }

    /// Returns the configured duration for a given timer mode.
    /// - Parameter mode: The timer mode to query.
    /// - Returns: Duration in seconds.
    func durationFor(mode: TimerMode) -> TimeInterval {
        switch mode {
        case .focus: focusDuration
        case .shortBreak: shortBreakDuration
        case .longBreak: longBreakDuration
        }
    }
}
