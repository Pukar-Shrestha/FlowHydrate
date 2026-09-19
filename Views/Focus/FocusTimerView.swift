import SwiftUI
import SwiftData

/// The primary focus timer screen — the hero view of FlowHydrate.
///
/// Centers a large animated circular progress ring with the remaining time,
/// surrounded by mode and session indicators. Control buttons adapt to the
/// current timer state (idle / running / paused) and mode (focus / break).
/// All colors and gradients transition smoothly when the timer mode changes.
struct FocusTimerView: View {
    /// The focus timer view model from the environment.
    @Environment(FocusTimerViewModel.self) private var timerVM

    /// The settings view model from the environment.
    @Environment(SettingsViewModel.self) private var settingsVM

    /// SwiftData model context for data operations.
    @Environment(\.modelContext) private var modelContext

    /// Whether the user has Reduce Motion enabled.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Controls presentation of the completion overlay.
    @State private var showCompletion = false

    /// Tracks whether the view has appeared for entrance animation.
    @State private var hasAppeared = false

    /// The total number of sessions in a Pomodoro cycle (typically 4).
    private let totalSessionsInCycle = 4

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                mainContent
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                settingsVM.loadSettings(modelContext: modelContext)
                withAnimation(reduceMotion ? .none : .spring(duration: 0.6)) {
                    hasAppeared = true
                }
            }
            .overlay {
                if showCompletion {
                    FocusCompletionView(isPresented: $showCompletion)
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Background

    /// A subtle radial background gradient that shifts with the current mode.
    private var backgroundGradient: some View {
        RadialGradient(
            colors: [
                timerVM.currentMode.color.opacity(0.08),
                Color(.systemBackground)
            ],
            center: .center,
            startRadius: 20,
            endRadius: 400
        )
        .ignoresSafeArea()
        .animation(
            reduceMotion ? .none : .easeInOut(duration: 0.8),
            value: timerVM.currentMode
        )
    }

    // MARK: - Main Content

    /// The vertically centered main content stack.
    private var mainContent: some View {
        VStack(spacing: 32) {
            Spacer()
            modeIndicator
            sessionCounter
            timerRing
            controlButtons
            sessionDots
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Mode Indicator

    /// Displays the current mode name with its accent color.
    private var modeIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: timerVM.currentMode.icon)
                .font(.subheadline)

            Text(timerVM.currentMode.displayName)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .foregroundStyle(timerVM.currentMode.color)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(timerVM.currentMode.color.opacity(0.12))
        )
        .animation(
            reduceMotion ? .none : .spring(duration: 0.5),
            value: timerVM.currentMode
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : -10)
        .accessibilityLabel("Current mode: \(timerVM.currentMode.displayName)")
    }

    // MARK: - Session Counter

    /// Shows the current session number within the Pomodoro cycle.
    private var sessionCounter: some View {
        Text("Session \(timerVM.currentSessionNumber) of \(totalSessionsInCycle)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .opacity(hasAppeared ? 1 : 0)
            .accessibilityLabel(
                "Session \(timerVM.currentSessionNumber) of \(totalSessionsInCycle)"
            )
    }

    // MARK: - Timer Ring

    /// The large circular progress ring with the time display centered inside.
    private var timerRing: some View {
        ZStack {
            CircularProgressRing(
                progress: timerVM.progress,
                lineWidth: 12,
                gradient: timerVM.currentMode.gradient,
                size: 280
            )

            VStack(spacing: 8) {
                AnimatedTimeDisplay(
                    seconds: timerVM.remainingSeconds,
                    font: .system(size: 56, weight: .thin, design: .rounded)
                )
                .accessibilityLabel("Time remaining: \(timerVM.formattedTime)")
                .accessibilityValue(timerVM.formattedTime)

                Image(systemName: timerVM.currentMode.icon)
                    .font(.title3)
                    .foregroundStyle(timerVM.currentMode.color.opacity(0.6))
                    .accessibilityHidden(true)
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1.0 : 0.9)
        .animation(
            reduceMotion ? .none : .spring(duration: 0.7, bounce: 0.3),
            value: hasAppeared
        )
        .animation(
            reduceMotion ? .none : .easeInOut(duration: 0.6),
            value: timerVM.currentMode
        )
    }

    // MARK: - Control Buttons

    /// Adaptive control buttons that change layout based on timer state.
    private var controlButtons: some View {
        HStack(spacing: 20) {
            switch timerVM.timerState {
            case .idle:
                idleControls
            case .running:
                runningControls
            case .paused:
                pausedControls
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(
            reduceMotion ? .none : .spring(duration: 0.5).delay(0.2),
            value: hasAppeared
        )
        .animation(
            reduceMotion ? .none : .spring(duration: 0.4),
            value: timerVM.timerState
        )
    }

    /// Controls displayed when the timer is idle.
    @ViewBuilder
    private var idleControls: some View {
        GradientButton(
            title: startButtonTitle,
            icon: "play.fill",
            gradient: timerVM.currentMode.gradient
        ) {
            HapticService.shared.medium()
            timerVM.start(
                settings: settingsVM,
                modelContext: modelContext
            )
        }
        .accessibilityHint("Starts the \(timerVM.currentMode.displayName) timer")
    }

    /// Controls displayed when the timer is running.
    @ViewBuilder
    private var runningControls: some View {
        pauseButton
        stopButton
        if isBreakMode {
            skipBreakButton
        }
    }

    /// Controls displayed when the timer is paused.
    @ViewBuilder
    private var pausedControls: some View {
        resumeButton
        stopButton
    }

    // MARK: - Individual Buttons

    /// The pause button.
    private var pauseButton: some View {
        controlCircleButton(
            icon: "pause.fill",
            label: "Pause",
            hint: "Pauses the timer",
            fillColor: timerVM.currentMode.color.opacity(0.15),
            foreground: timerVM.currentMode.color
        ) {
            HapticService.shared.light()
            timerVM.pause()
        }
    }

    /// The resume button.
    private var resumeButton: some View {
        GradientButton(
            title: "Resume",
            icon: "play.fill",
            gradient: timerVM.currentMode.gradient
        ) {
            HapticService.shared.medium()
            timerVM.resume()
        }
        .accessibilityHint("Resumes the paused timer")
    }

    /// The stop button.
    private var stopButton: some View {
        controlCircleButton(
            icon: "stop.fill",
            label: "Stop",
            hint: "Stops and resets the timer",
            fillColor: Color.red.opacity(0.12),
            foreground: .red
        ) {
            HapticService.shared.warning()
            timerVM.stop()
        }
    }

    /// A button to skip the current break.
    private var skipBreakButton: some View {
        Button {
            HapticService.shared.light()
            timerVM.skip(
                settings: settingsVM,
                modelContext: modelContext
            )
        } label: {
            Text("Skip Break")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(timerVM.currentMode.color)
        }
        .accessibilityLabel("Skip Break")
        .accessibilityHint("Skips the current break and starts a new focus session")
    }

    /// A reusable circular icon button with custom fill and foreground color.
    private func controlCircleButton(
        icon: String,
        label: String,
        hint: String,
        fillColor: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(foreground)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(fillColor)
                )
        }
        .accessibilityLabel(label)
        .accessibilityHint(hint)
    }

    // MARK: - Session Dots

    /// Visual indicator showing completed sessions as filled dots.
    private var sessionDots: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalSessionsInCycle, id: \.self) { index in
                Circle()
                    .fill(
                        index < timerVM.sessionsCompleted
                            ? AnyShapeStyle(timerVM.currentMode.gradient)
                            : AnyShapeStyle(Color.secondary.opacity(0.2))
                    )
                    .frame(width: 10, height: 10)
                    .scaleEffect(
                        index < timerVM.sessionsCompleted ? 1.0 : 0.8
                    )
                    .animation(
                        reduceMotion ? .none : .spring(duration: 0.4),
                        value: timerVM.sessionsCompleted
                    )
            }
        }
        .accessibilityLabel(
            "\(timerVM.sessionsCompleted) of \(totalSessionsInCycle) sessions completed"
        )
        .opacity(hasAppeared ? 1 : 0)
        .animation(
            reduceMotion ? .none : .spring(duration: 0.5).delay(0.3),
            value: hasAppeared
        )
    }

    // MARK: - Helpers

    /// Whether the current mode is a break (short or long).
    private var isBreakMode: Bool {
        timerVM.currentMode != .focus
    }

    /// The title for the start button based on the current mode.
    private var startButtonTitle: String {
        switch timerVM.currentMode {
        case .focus: "Start Focus"
        case .shortBreak: "Start Break"
        case .longBreak: "Start Break"
        }
    }
}

#Preview("Idle State") {
    FocusTimerView()
        .environment(FocusTimerViewModel())
        .environment(SettingsViewModel())
        .modelContainer(PersistenceService.sharedModelContainer)
}
