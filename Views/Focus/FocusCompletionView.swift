import SwiftUI
import SwiftData

/// A full-screen celebration overlay displayed when a focus or break session completes.
///
/// Shows an animated icon, congratulatory message, session statistics, and a
/// context-aware call-to-action. Includes confetti for milestone celebrations and
/// auto-dismisses after 5 seconds when auto-start is enabled.
struct FocusCompletionView: View {
    /// Binding controlling whether this overlay is presented.
    @Binding var isPresented: Bool

    /// The focus timer view model from the environment.
    @Environment(FocusTimerViewModel.self) private var timerVM

    /// The settings view model from the environment.
    @Environment(SettingsViewModel.self) private var settingsVM

    /// The streak view model from the environment.
    @Environment(StreakViewModel.self) private var streakVM

    /// SwiftData model context for data operations.
    @Environment(\.modelContext) private var modelContext

    /// Whether the user has Reduce Motion enabled.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Controls the entrance animation of the content.
    @State private var contentVisible = false

    /// Controls the pulsing animation of the hero icon.
    @State private var iconPulsing = false

    /// Controls the confetti celebration overlay.
    @State private var showConfetti = false

    /// Timer for auto-dismiss when auto-start is enabled.
    @State private var autoDismissTask: Task<Void, Never>?

    /// Whether the completed session was a focus session (vs. a break).
    private var wasFocusSession: Bool {
        timerVM.currentMode == .focus
    }

    /// Duration of the completed session in minutes.
    private var completedMinutes: Int {
        timerVM.totalSeconds / 60
    }

    var body: some View {
        ZStack {
            dismissBackground
            contentCard
            confettiOverlay
        }
        .onAppear {
            performEntranceAnimation()
            scheduleAutoDismissIfNeeded()
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }

    // MARK: - Background

    /// Semi-transparent tappable background that dismisses the overlay.
    private var dismissBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .onTapGesture {
                dismiss()
            }
            .accessibilityHidden(true)
    }

    // MARK: - Content Card

    /// The main content card with icon, message, stats, and action buttons.
    private var contentCard: some View {
        VStack(spacing: 28) {
            heroIcon
            titleSection
            statsSection
            actionButtons
            skipButton
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        )
        .padding(.horizontal, 32)
        .opacity(contentVisible ? 1 : 0)
        .scaleEffect(contentVisible ? 1.0 : 0.8)
        .offset(y: contentVisible ? 0 : 30)
    }

    // MARK: - Hero Icon

    /// Animated checkmark or brain icon celebrating the completed session.
    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    timerVM.currentMode.color.opacity(0.15)
                )
                .frame(width: 88, height: 88)
                .scaleEffect(iconPulsing ? 1.1 : 1.0)
                .animation(
                    reduceMotion
                        ? .none
                        : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: iconPulsing
                )

            Image(systemName: wasFocusSession ? "checkmark.circle.fill" : "brain.head.profile")
                .font(.system(size: 44))
                .foregroundStyle(timerVM.currentMode.color)
                .symbolEffect(
                    .bounce,
                    value: contentVisible
                )
        }
        .accessibilityHidden(true)
    }

    // MARK: - Title

    /// The congratulatory title and context message.
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(titleText)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(subtitleText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(titleText). \(subtitleText)")
    }

    /// The primary congratulatory text.
    private var titleText: String {
        wasFocusSession ? "Great work! 🎉" : "Break complete!"
    }

    /// Contextual subtitle suggesting the next action.
    private var subtitleText: String {
        wasFocusSession
            ? "Time for a well-deserved break."
            : "Ready to focus again?"
    }

    // MARK: - Stats

    /// Session statistics displayed in a horizontal layout.
    private var statsSection: some View {
        HStack(spacing: 24) {
            statItem(
                label: "Duration",
                value: "\(completedMinutes) min",
                icon: "clock.fill"
            )

            Divider()
                .frame(height: 36)

            statItem(
                label: "Sessions",
                value: "\(timerVM.sessionsCompleted)",
                icon: "flame.fill"
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    /// A single stat item with an icon, label, and value.
    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(timerVM.currentMode.color)
                .accessibilityHidden(true)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Action Buttons

    /// Context-aware call-to-action button.
    private var actionButtons: some View {
        GradientButton(
            title: actionButtonTitle,
            icon: actionButtonIcon,
            gradient: timerVM.currentMode.gradient
        ) {
            HapticService.shared.medium()
            timerVM.start(
                settings: settingsVM,
                modelContext: modelContext
            )
            dismiss()
        }
        .accessibilityHint(actionButtonHint)
    }

    /// The action button title based on the completed session type.
    private var actionButtonTitle: String {
        wasFocusSession ? "Start Break" : "Start Focus"
    }

    /// The action button icon based on the completed session type.
    private var actionButtonIcon: String {
        wasFocusSession ? "cup.and.saucer.fill" : "brain.head.profile"
    }

    /// The accessibility hint for the action button.
    private var actionButtonHint: String {
        wasFocusSession
            ? "Starts a break timer"
            : "Starts a new focus session"
    }

    // MARK: - Skip Button

    /// A text button to dismiss the overlay without starting the next session.
    private var skipButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Skip")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Skip")
        .accessibilityHint("Dismisses the completion screen without starting a new session")
    }

    // MARK: - Confetti

    /// Confetti overlay for milestone celebrations.
    @ViewBuilder
    private var confettiOverlay: some View {
        if showConfetti {
            ConfettiView(isActive: $showConfetti)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Animations

    /// Triggers the entrance animation for the content card and icon.
    private func performEntranceAnimation() {
        withAnimation(
            reduceMotion ? .none : .spring(duration: 0.6, bounce: 0.4)
        ) {
            contentVisible = true
        }

        iconPulsing = true

        if streakVM.showCelebration {
            showConfetti = true
        }
    }

    /// Schedules auto-dismiss after 5 seconds if auto-start is configured.
    private func scheduleAutoDismissIfNeeded() {
        autoDismissTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                dismiss()
            }
        }
    }

    // MARK: - Dismiss

    /// Dismisses the overlay with an animation.
    private func dismiss() {
        withAnimation(reduceMotion ? .none : .easeOut(duration: 0.3)) {
            contentVisible = false
        }

        Task {
            try? await Task.sleep(for: .milliseconds(300))
            isPresented = false
        }
    }
}

#Preview("Focus Complete") {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        FocusCompletionView(isPresented: .constant(true))
    }
    .environment(FocusTimerViewModel())
    .environment(SettingsViewModel())
    .environment(StreakViewModel())
    .modelContainer(PersistenceService.sharedModelContainer)
}
