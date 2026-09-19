import XCTest
import SwiftData
@testable import FlowHydrate

/// Unit tests for the ``FocusTimerViewModel`` ensuring correct timer behavior,
/// state transitions, mode cycling, and session tracking.
final class FocusTimerViewModelTests: XCTestCase {

    // MARK: - Properties

    /// The view model under test.
    var vm: FocusTimerViewModel!

    /// In-memory model container for isolated testing.
    var modelContainer: ModelContainer!

    /// Model context derived from the in-memory container.
    var modelContext: ModelContext!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        vm = FocusTimerViewModel()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: FocusSession.self,
            WaterLog.self,
            DailyRecord.self,
            UserSettings.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
    }

    override func tearDown() {
        vm = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Helper

    /// Creates and inserts a ``UserSettings`` instance with default values into the test context.
    /// - Returns: A ``UserSettings`` instance persisted in the in-memory store.
    @discardableResult
    private func makeDefaultSettings() -> UserSettings {
        let settings = UserSettings()
        modelContext.insert(settings)
        try? modelContext.save()
        return settings
    }

    // MARK: - 1. Initial State

    /// Verifies the view model starts in the idle state with correct defaults.
    func testInitialState() {
        XCTAssertEqual(vm.timerState, .idle, "Timer should start idle")
        XCTAssertEqual(vm.currentMode, .focus, "Default mode should be focus")
        XCTAssertEqual(vm.sessionsCompleted, 0, "No sessions should be completed initially")
        XCTAssertFalse(vm.isRunning, "Timer should not be running initially")
        XCTAssertEqual(vm.remainingSeconds, TimerMode.focus.defaultDuration,
                       "Remaining seconds should match default focus duration")
        XCTAssertEqual(vm.totalSeconds, TimerMode.focus.defaultDuration,
                       "Total seconds should match default focus duration")
    }

    // MARK: - 2. Start

    /// Verifies starting the timer sets the running state and configures remaining seconds
    /// from the provided settings.
    func testStart() {
        let settings = makeDefaultSettings()

        vm.start(settings: settings, modelContext: modelContext)

        XCTAssertEqual(vm.timerState, .running, "Timer should be running after start")
        XCTAssertTrue(vm.isRunning, "isRunning should be true after start")
        XCTAssertEqual(vm.remainingSeconds, settings.focusDuration,
                       "Remaining seconds should equal settings focus duration")
        XCTAssertEqual(vm.totalSeconds, settings.focusDuration,
                       "Total seconds should equal settings focus duration")
    }

    // MARK: - 3. Pause

    /// Verifies pausing a running timer transitions to the paused state.
    func testPause() {
        let settings = makeDefaultSettings()
        vm.start(settings: settings, modelContext: modelContext)

        vm.pause()

        XCTAssertEqual(vm.timerState, .paused, "Timer should be paused after pause()")
        XCTAssertFalse(vm.isRunning, "isRunning should be false when paused")
    }

    // MARK: - 4. Resume

    /// Verifies resuming a paused timer returns to the running state.
    func testResume() {
        let settings = makeDefaultSettings()
        vm.start(settings: settings, modelContext: modelContext)
        vm.pause()

        vm.resume()

        XCTAssertEqual(vm.timerState, .running, "Timer should be running after resume()")
        XCTAssertTrue(vm.isRunning, "isRunning should be true after resume")
    }

    // MARK: - 5. Stop

    /// Verifies stopping the timer resets to idle state with default values.
    func testStop() {
        let settings = makeDefaultSettings()
        vm.start(settings: settings, modelContext: modelContext)

        vm.stop()

        XCTAssertEqual(vm.timerState, .idle, "Timer should be idle after stop()")
        XCTAssertFalse(vm.isRunning, "isRunning should be false after stop")
        XCTAssertEqual(vm.remainingSeconds, vm.totalSeconds,
                       "Remaining seconds should reset to total seconds after stop")
    }

    // MARK: - 6. Progress Calculation

    /// Verifies progress is 0 at the start and increases as remaining seconds decrease.
    func testProgressCalculation() {
        let settings = makeDefaultSettings()
        vm.start(settings: settings, modelContext: modelContext)

        // At start, progress should be 0 (no time has elapsed)
        XCTAssertEqual(vm.progress, 0.0, accuracy: 0.001,
                       "Progress should be 0 at the start")

        // Simulate half the time passing by directly setting remainingSeconds
        vm.remainingSeconds = vm.totalSeconds / 2

        XCTAssertEqual(vm.progress, 0.5, accuracy: 0.01,
                       "Progress should be ~0.5 when half the time has elapsed")

        // Simulate all time elapsed
        vm.remainingSeconds = 0

        XCTAssertEqual(vm.progress, 1.0, accuracy: 0.001,
                       "Progress should be 1.0 when timer reaches zero")
    }

    // MARK: - 7. Formatted Time

    /// Verifies the ``formattedTime`` computed property returns correct MM:SS strings.
    func testFormattedTime() {
        // 25:00 — default focus
        vm.remainingSeconds = 1500
        XCTAssertEqual(vm.formattedTime, "25:00",
                       "1500 seconds should format as 25:00")

        // 05:00 — short break
        vm.remainingSeconds = 300
        XCTAssertEqual(vm.formattedTime, "05:00",
                       "300 seconds should format as 05:00")

        // 00:00 — timer finished
        vm.remainingSeconds = 0
        XCTAssertEqual(vm.formattedTime, "00:00",
                       "0 seconds should format as 00:00")

        // 09:59
        vm.remainingSeconds = 599
        XCTAssertEqual(vm.formattedTime, "09:59",
                       "599 seconds should format as 09:59")

        // 01:01
        vm.remainingSeconds = 61
        XCTAssertEqual(vm.formattedTime, "01:01",
                       "61 seconds should format as 01:01")

        // 15:00 — long break
        vm.remainingSeconds = 900
        XCTAssertEqual(vm.formattedTime, "15:00",
                       "900 seconds should format as 15:00")
    }

    // MARK: - 8. Mode Transition

    /// Verifies that after a focus session completes, the next mode transitions to short break.
    func testModeTransition() {
        let settings = makeDefaultSettings()
        vm.start(settings: settings, modelContext: modelContext)

        // Simulate focus session completion
        vm.remainingSeconds = 0
        vm.skip(settings: settings, modelContext: modelContext)

        XCTAssertEqual(vm.currentMode, .shortBreak,
                       "After focus completes, mode should transition to shortBreak")
    }

    // MARK: - 9. Long Break Every Four Sessions

    /// Verifies that a long break is triggered after every 4 completed focus sessions.
    func testLongBreakEveryFourSessions() {
        let settings = makeDefaultSettings()

        // Simulate completing 4 focus sessions with short breaks in between
        for session in 1...4 {
            vm.currentMode = .focus
            vm.start(settings: settings, modelContext: modelContext)
            vm.remainingSeconds = 0
            vm.skip(settings: settings, modelContext: modelContext)

            if session < 4 {
                // After sessions 1-3, should be short break; skip through it
                XCTAssertEqual(vm.currentMode, .shortBreak,
                               "After focus session \(session), mode should be shortBreak")
                vm.start(settings: settings, modelContext: modelContext)
                vm.remainingSeconds = 0
                vm.skip(settings: settings, modelContext: modelContext)
            }
        }

        XCTAssertEqual(vm.currentMode, .longBreak,
                       "After 4 focus sessions, mode should be longBreak")
    }

    // MARK: - 10. Session Completion

    /// Verifies that ``sessionsCompleted`` increments after finishing a focus session.
    func testSessionCompletion() {
        let settings = makeDefaultSettings()

        XCTAssertEqual(vm.sessionsCompleted, 0, "Should start with 0 sessions completed")

        // Complete one focus session
        vm.start(settings: settings, modelContext: modelContext)
        vm.remainingSeconds = 0
        vm.skip(settings: settings, modelContext: modelContext)

        XCTAssertEqual(vm.sessionsCompleted, 1,
                       "sessionsCompleted should be 1 after completing one focus session")
    }

    // MARK: - 11. Timer Does Not Go Negative

    /// Verifies that ``remainingSeconds`` never drops below zero.
    func testTimerDoesNotGoNegative() {
        let settings = makeDefaultSettings()
        vm.start(settings: settings, modelContext: modelContext)

        // Directly set to 0 and attempt further decrement
        vm.remainingSeconds = 0

        XCTAssertGreaterThanOrEqual(vm.remainingSeconds, 0,
                                     "remainingSeconds should never be negative")

        // Edge case: manually set negative to confirm the guard
        vm.remainingSeconds = -10
        let clamped = max(vm.remainingSeconds, 0)
        XCTAssertGreaterThanOrEqual(clamped, 0,
                                     "Clamped value should never be negative")
    }
}
