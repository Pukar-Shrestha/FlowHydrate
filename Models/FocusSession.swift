import Foundation
import SwiftData

/// A completed or abandoned focus timer session persisted with SwiftData.
///
/// Each session records when it started, how long it ran, which mode was active,
/// and whether the user saw it through to completion.
@Model
final class FocusSession {
    /// Unique identifier for this session
    var id: UUID = UUID()

    /// When the session was started
    var startDate: Date = Date()

    /// When the session ended, or `nil` if it was abandoned
    var endDate: Date? = nil

    /// Planned duration in seconds
    var duration: TimeInterval = 1500

    /// Raw string backing for the `mode` transient property
    var modeRawValue: String = TimerMode.focus.rawValue

    /// Whether the session ran to completion
    var completed: Bool = false

    /// The timer mode for this session, derived from the persisted raw value.
    @Transient
    var mode: TimerMode {
        get { TimerMode(rawValue: modeRawValue) ?? .focus }
        set { modeRawValue = newValue.rawValue }
    }

    /// Duration expressed in minutes for display purposes.
    @Transient
    var durationMinutes: Double { duration / 60.0 }

    /// Creates a new focus session.
    /// - Parameters:
    ///   - mode: The timer mode (focus, short break, or long break).
    ///   - duration: Planned duration in seconds.
    init(mode: TimerMode, duration: TimeInterval) {
        self.id = UUID()
        self.startDate = Date()
        self.duration = duration
        self.modeRawValue = mode.rawValue
        self.completed = false
    }
}
