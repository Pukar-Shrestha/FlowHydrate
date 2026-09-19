import Foundation
import UserNotifications

/// Manages all local notifications for focus timer completion and hydration reminders.
///
/// Provides actionable notifications with custom categories so users can respond
/// directly from the notification banner (e.g., "Log Water" on hydration reminders).
final class NotificationService: Sendable {
    /// Shared singleton instance
    static let shared = NotificationService()

    // MARK: - Notification Identifiers

    /// Category identifier for focus session completion notifications
    private let focusCategoryID = "FOCUS_COMPLETE"

    /// Category identifier for hydration reminder notifications
    private let hydrationCategoryID = "HYDRATION_REMINDER"

    /// Category identifier for post-focus hydration suggestion notifications
    private let postFocusHydrationCategoryID = "POST_FOCUS_HYDRATION"

    /// Request identifier prefix for focus notifications
    private let focusRequestPrefix = "focus-complete"

    /// Request identifier for repeating hydration reminders
    private let hydrationRequestID = "hydration-reminder"

    /// Request identifier for post-focus hydration suggestions
    private let postFocusHydrationRequestID = "post-focus-hydration"

    /// Action identifier for the "Log Water" button
    private let logWaterActionID = "LOG_WATER_ACTION"

    private init() {
        registerCategories()
    }

    // MARK: - Category Registration

    /// Registers notification categories with their associated actions.
    private func registerCategories() {
        let logWaterAction = UNNotificationAction(
            identifier: logWaterActionID,
            title: "Log Water",
            options: .foreground
        )

        let focusCategory = UNNotificationCategory(
            identifier: focusCategoryID,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let hydrationCategory = UNNotificationCategory(
            identifier: hydrationCategoryID,
            actions: [logWaterAction],
            intentIdentifiers: [],
            options: []
        )

        let postFocusHydrationCategory = UNNotificationCategory(
            identifier: postFocusHydrationCategoryID,
            actions: [logWaterAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            focusCategory,
            hydrationCategory,
            postFocusHydrationCategory
        ])
    }

    // MARK: - Authorization

    /// Requests notification authorization from the user.
    /// - Returns: `true` if authorization was granted, `false` otherwise.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Focus Notifications

    /// Schedules a notification for when the current focus or break session completes.
    /// - Parameter mode: The timer mode that will complete.
    func scheduleFocusComplete(mode: TimerMode) {
        let content = UNMutableNotificationContent()

        switch mode {
        case .focus:
            content.title = "Focus Session Complete 🎯"
            content.body = "Great work! Time to take a break."
        case .shortBreak:
            content.title = "Break Over ☕️"
            content.body = "Ready to dive back in? Start your next focus session."
        case .longBreak:
            content.title = "Long Break Over 🌿"
            content.body = "Refreshed? Let's get back to it!"
        }

        content.sound = .default
        content.categoryIdentifier = focusCategoryID

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: mode.defaultDuration,
            repeats: false
        )

        let requestID = "\(focusRequestPrefix)-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: requestID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Hydration Notifications

    /// Schedules a repeating hydration reminder notification.
    /// - Parameter interval: Time interval in seconds between reminders.
    func scheduleHydrationReminder(after interval: TimeInterval) {
        cancelHydrationReminders()

        let content = UNMutableNotificationContent()
        content.title = "Stay Hydrated 💧"
        content.body = "Time to drink some water! Your body will thank you."
        content.sound = .default
        content.categoryIdentifier = hydrationCategoryID

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(interval, 60),
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: hydrationRequestID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Suggests drinking water after completing a focus session.
    func schedulePostFocusHydration() {
        let content = UNMutableNotificationContent()
        content.title = "Hydration Check 💧"
        content.body = "You just finished a focus session — grab some water!"
        content.sound = .default
        content.categoryIdentifier = postFocusHydrationCategoryID

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: postFocusHydrationRequestID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancellation

    /// Cancels all pending notifications managed by this service.
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Cancels only the repeating hydration reminder.
    private func cancelHydrationReminders() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [hydrationRequestID])
    }
}
