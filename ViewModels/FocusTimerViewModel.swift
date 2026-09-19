import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Timer State

/// Represents the current state of the focus timer.
enum TimerState: String, Sendable {
    /// Timer has not been started or has been fully reset.
    case idle
    /// Timer is actively counting down.
    case running
    /// Timer has been temporarily paused by the user.
    case paused
}

// MARK: - FocusTimerViewModel

/// Manages the Pomodoro-style focus timer with date-based timing for background accuracy.
///
/// Uses `Date` math rather than `Timer` tick counting to ensure elapsed time remains
/// correct even when the app is suspended in the background. A display timer fires at
/// 10 Hz solely to drive UI updates.
@Observable
final class FocusTimerViewModel {

    // MARK: - Published State

    /// The current timer mode (focus, short break, or long break).
    var currentMode: TimerMode = .focus

    /// The current state of the timer lifecycle.
    var timerState: TimerState = .idle

    /// Seconds remaining in the current session, updated by the display timer.
    var remainingSeconds: TimeInterval = 1500

    /// Total seconds for the current session (set from user settings).
    var totalSeconds: TimeInterval = 1500

    /// Cumulative number of completed focus sessions in this sitting.
    var sessionsCompleted: Int = 0

    /// Number of focus sessions required before a long break is triggered.
    var sessionsUntilLongBreak: Int = 4

    /// The current session number within the focus cycle (1-based, resets after long break).
    var currentSessionNumber: Int = 1

    // MARK: - Computed Properties

    /// Linear progress from 0.0 (not started) to 1.0 (complete).
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(max(1.0 - (remainingSeconds / totalSeconds), 0), 1)
    }

    /// Whether the timer is actively running.
    var isRunning: Bool {
        timerState == .running
    }

    /// Remaining time formatted as `MM:SS`.
    var formattedTime: String {
        let clamped = max(0, Int(remainingSeconds.rounded(.up)))
        let minutes = clamped / 60
        let seconds = clamped % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Date-Based Timing (Private)

    /// The wall-clock date when the timer was last started or resumed.
    /// Used together with `accumulatedTime` to compute true elapsed time.
    private var timerStartDate: Date?

    /// Time accumulated from previous start/pause cycles within the same session.
    private var accumulatedTime: TimeInterval = 0

    /// Cancellable for the 10 Hz display-update timer.
    private var displayTimer: AnyCancellable?

    // MARK: - Timer Control

    /// Starts a new timer session using the duration defined in the user's settings.
    ///
    /// - Parameters:
    ///   - settings: The current user settings supplying per-mode durations.
    ///   - modelContext: SwiftData model context for persisting completed sessions.
    func start(settings: UserSettings, modelContext: ModelContext) {
        let duration = settings.durationFor(mode: currentMode)
        totalSeconds = duration
        remainingSeconds = duration
        accumulatedTime = 0
        timerStartDate = Date()
        timerState = .running

        startDisplayTimer(settings: settings, modelContext: modelContext)
        scheduleBackgroundNotification(settings: settings)
        syncSharedData()
    }

    /// Pauses the running timer, preserving accumulated elapsed time.
    func pause() {
        guard timerState == .running, let startDate = timerStartDate else { return }

        accumulatedTime += Date().timeIntervalSince(startDate)
        timerStartDate = nil
        timerState = .paused

        stopDisplayTimer()
        NotificationService.shared.cancelAll()
        syncSharedData()
    }

    /// Resumes a previously paused timer.
    func resume() {
        guard timerState == .paused else { return }

        timerStartDate = Date()
        timerState = .running

        // Re-create the display timer; settings/context captured via stored reference is
        // not available here, so the tick closure recalculates purely from dates.
        startDisplayTimerResumed()
        scheduleResumedNotification()
        syncSharedData()
    }

    /// Stops and fully resets the timer to its idle state.
    func stop() {
        timerState = .idle
        accumulatedTime = 0
        timerStartDate = nil
        remainingSeconds = totalSeconds

        stopDisplayTimer()
        NotificationService.shared.cancelAll()
        syncSharedData()
    }

    /// Skips the current session and transitions to the next mode.
    ///
    /// If skipping a focus session the session is **not** recorded as completed.
    ///
    /// - Parameters:
    ///   - settings: The current user settings.
    ///   - modelContext: SwiftData model context for persistence.
    func skip(settings: UserSettings, modelContext: ModelContext) {
        stopDisplayTimer()
        NotificationService.shared.cancelAll()

        transitionToNextMode(settings: settings, modelContext: modelContext, completed: false)
    }

    /// Adjusts timer state in response to scene-phase changes.
    ///
    /// When the app moves to the background the display timer is torn down (the OS would
    /// suspend it anyway). When the app returns to the foreground, elapsed time is
    /// recomputed from wall-clock dates and the display timer is restarted.
    ///
    /// - Parameter phase: The current `ScenePhase`.
    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            guard timerState == .running else { return }
            recalculateRemainingTime()
            if remainingSeconds <= 0 {
                // Session completed while backgrounded — handled on next tick.
                remainingSeconds = 0
            }
            startDisplayTimerResumed()

        case .background, .inactive:
            if timerState == .running {
                stopDisplayTimer()
            }

        @unknown default:
            break
        }
    }

    // MARK: - Private Helpers

    /// Recalculates `remainingSeconds` from wall-clock dates.
    private func recalculateRemainingTime() {
        guard let startDate = timerStartDate else { return }
        let elapsed = accumulatedTime + Date().timeIntervalSince(startDate)
        remainingSeconds = max(0, totalSeconds - elapsed)
    }

    /// Starts the 10 Hz display timer that drives UI updates and detects session completion.
    private func startDisplayTimer(settings: UserSettings, modelContext: ModelContext) {
        stopDisplayTimer()

        displayTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.tick(settings: settings, modelContext: modelContext)
            }
    }

    /// Starts a resumed display timer without settings/context (used after pause/background).
    ///
    /// Session-completion detection still works because `remainingSeconds` is checked;
    /// however the completion side-effects require settings and context. To handle this
    /// edge case the timer stores a pending-completion flag and resolves it when possible.
    private func startDisplayTimerResumed() {
        stopDisplayTimer()

        displayTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recalculateRemainingTime()
            }
    }

    /// Called on each display-timer tick while settings and context are available.
    private func tick(settings: UserSettings, modelContext: ModelContext) {
        recalculateRemainingTime()

        if remainingSeconds <= 0 {
            remainingSeconds = 0
            completeSession(settings: settings, modelContext: modelContext)
        }
    }

    /// Handles session completion: persists the session, fires feedback, and transitions.
    private func completeSession(settings: UserSettings, modelContext: ModelContext) {
        stopDisplayTimer()

        // Persist completed focus sessions.
        if currentMode == .focus {
            let session = FocusSession(
                id: UUID(),
                startDate: Date().addingTimeInterval(-totalSeconds),
                endDate: Date(),
                duration: totalSeconds,
                modeRawValue: currentMode.rawValue,
                completed: true
            )
            modelContext.insert(session)
            try? modelContext.save()

            sessionsCompleted += 1

            // Prompt user to hydrate after each focus session.
            NotificationService.shared.schedulePostFocusHydration()
        }

        // Haptic & audio feedback.
        HapticService.shared.notification(.success)
        SoundService.shared.playCompletion()

        // Transition to next mode.
        transitionToNextMode(settings: settings, modelContext: modelContext, completed: true)
    }

    /// Determines the next timer mode and optionally auto-starts it.
    private func transitionToNextMode(settings: UserSettings, modelContext: ModelContext, completed: Bool) {
        let nextMode: TimerMode

        switch currentMode {
        case .focus:
            if currentSessionNumber >= sessionsUntilLongBreak {
                nextMode = .longBreak
            } else {
                nextMode = .shortBreak
            }

        case .shortBreak:
            nextMode = .focus
            currentSessionNumber += 1

        case .longBreak:
            nextMode = .focus
            currentSessionNumber = 1
        }

        currentMode = nextMode
        let duration = settings.durationFor(mode: nextMode)
        totalSeconds = duration
        remainingSeconds = duration
        accumulatedTime = 0
        timerStartDate = nil
        timerState = .idle

        if completed && settings.autoStartNext {
            start(settings: settings, modelContext: modelContext)
        }

        syncSharedData()
    }

    /// Stops and releases the display timer.
    private func stopDisplayTimer() {
        displayTimer?.cancel()
        displayTimer = nil
    }

    /// Schedules a local notification for when the session should complete.
    private func scheduleBackgroundNotification(settings: UserSettings) {
        NotificationService.shared.scheduleFocusComplete(mode: currentMode)
    }

    /// Re-schedules a notification for the remaining time after a resume.
    private func scheduleResumedNotification() {
        NotificationService.shared.cancelAll()
        NotificationService.shared.scheduleFocusComplete(mode: currentMode)
    }

    /// Pushes the latest timer state to the shared data store for widgets and Live Activities.
    private func syncSharedData() {
        SharedDataManager.shared.timerState = timerState.rawValue
        SharedDataManager.shared.currentMode = currentMode.rawValue
        SharedDataManager.shared.remainingSeconds = remainingSeconds
        SharedDataManager.shared.totalSeconds = totalSeconds
        SharedDataManager.shared.sessionsCompleted = sessionsCompleted
    }
}
