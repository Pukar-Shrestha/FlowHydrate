import ActivityKit
import Foundation
import Observation

/// Manages the lifecycle of Focus Timer Live Activities on Dynamic Island and the Lock Screen.
///
/// Provides methods to start, update, and end Live Activities, handling all error cases
/// gracefully. Uses the singleton pattern for centralized activity management.
@Observable
final class LiveActivityManager {
    /// Shared singleton instance.
    static let shared = LiveActivityManager()

    /// The currently active Live Activity instance, if one is running.
    private var currentActivity: Activity<FlowHydrateActivityAttributes>?

    /// Whether Live Activities are supported and enabled on this device.
    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Whether a Live Activity is currently active.
    var isActivityRunning: Bool {
        currentActivity != nil
    }

    private init() {}

    /// Starts a new Live Activity for a focus session.
    ///
    /// If a Live Activity is already running, it will be ended before starting the new one.
    /// If Live Activities are not supported or not authorized, this method returns silently.
    ///
    /// - Parameters:
    ///   - mode: The current timer mode (focus, shortBreak, or longBreak).
    ///   - totalSeconds: The total duration of the timer segment in seconds.
    func startFocusActivity(mode: TimerMode, totalSeconds: Int) {
        guard isSupported else {
            print("[LiveActivityManager] Live Activities are not supported or not enabled.")
            return
        }

        // End any existing activity before starting a new one
        if currentActivity != nil {
            Task {
                await endActivity()
                performStart(mode: mode, totalSeconds: totalSeconds)
            }
        } else {
            performStart(mode: mode, totalSeconds: totalSeconds)
        }
    }

    /// Performs the actual Live Activity start request.
    ///
    /// - Parameters:
    ///   - mode: The current timer mode.
    ///   - totalSeconds: The total duration in seconds.
    private func performStart(mode: TimerMode, totalSeconds: Int) {
        let attributes = FlowHydrateActivityAttributes(
            sessionName: mode.displayName,
            totalSeconds: totalSeconds,
            startTime: .now
        )

        let initialState = FlowHydrateActivityAttributes.ContentState(
            remainingSeconds: totalSeconds,
            progress: 0.0,
            modeName: mode.displayName,
            modeIcon: mode.icon
        )

        let content = ActivityContent(
            state: initialState,
            staleDate: Date.now.addingTimeInterval(TimeInterval(totalSeconds) + 60)
        )

        do {
            let activity = try Activity<FlowHydrateActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
            print("[LiveActivityManager] Started Live Activity: \(activity.id)")
        } catch {
            print("[LiveActivityManager] Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    /// Updates the Live Activity with the current timer state.
    ///
    /// Pushes new content state to the Dynamic Island and Lock Screen presentation.
    /// If no activity is currently running, this method returns silently.
    ///
    /// - Parameters:
    ///   - remainingSeconds: The number of seconds remaining in the session.
    ///   - progress: The session progress as a value from 0.0 to 1.0.
    ///   - mode: The current timer mode.
    func updateActivity(remainingSeconds: Int, progress: Double, mode: TimerMode) async {
        guard let activity = currentActivity else {
            return
        }

        let updatedState = FlowHydrateActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            progress: progress,
            modeName: mode.displayName,
            modeIcon: mode.icon
        )

        let content = ActivityContent(
            state: updatedState,
            staleDate: Date.now.addingTimeInterval(120)
        )

        await activity.update(content)
    }

    /// Ends the currently running Live Activity.
    ///
    /// Displays a final state showing "Session Complete" before dismissing.
    /// If no activity is currently running, this method returns silently.
    func endActivity() async {
        guard let activity = currentActivity else {
            return
        }

        let finalState = FlowHydrateActivityAttributes.ContentState(
            remainingSeconds: 0,
            progress: 1.0,
            modeName: "Complete",
            modeIcon: "checkmark.circle.fill"
        )

        let finalContent = ActivityContent(
            state: finalState,
            staleDate: .now.addingTimeInterval(5)
        )

        await activity.end(finalContent, dismissalPolicy: .after(.now.addingTimeInterval(5)))
        currentActivity = nil
        print("[LiveActivityManager] Ended Live Activity: \(activity.id)")
    }

    /// Ends all running Live Activities for the app.
    ///
    /// Useful for cleanup when the app launches or when resetting state.
    func endAllActivities() async {
        for activity in Activity<FlowHydrateActivityAttributes>.activities {
            let finalState = FlowHydrateActivityAttributes.ContentState(
                remainingSeconds: 0,
                progress: 1.0,
                modeName: "Complete",
                modeIcon: "checkmark.circle.fill"
            )

            let finalContent = ActivityContent(
                state: finalState,
                staleDate: .now.addingTimeInterval(5)
            )

            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
        currentActivity = nil
        print("[LiveActivityManager] Ended all Live Activities.")
    }
}
