import ActivityKit
import Foundation

/// Defines the attributes for the FlowHydrate Focus Timer Live Activity.
///
/// This structure describes both the static context (set when the activity starts)
/// and the dynamic content state (updated throughout the session).
struct FlowHydrateActivityAttributes: ActivityAttributes {
    /// Dynamic state updated during the focus session.
    ///
    /// This state is pushed to the system whenever the timer ticks or the mode changes,
    /// allowing the Dynamic Island and Lock Screen to reflect the current progress.
    struct ContentState: Codable, Hashable {
        /// The number of seconds remaining in the current timer segment.
        var remainingSeconds: Int

        /// The current progress of the timer as a value from 0.0 to 1.0.
        var progress: Double

        /// The display name of the current timer mode (e.g., "Focus", "Short Break").
        var modeName: String

        /// The SF Symbol name representing the current timer mode.
        var modeIcon: String
    }

    /// A human-readable name for the session (e.g., "Focus Session").
    let sessionName: String

    /// The total number of seconds for the timer segment.
    let totalSeconds: Int

    /// The date and time when the session was started.
    let startTime: Date
}
