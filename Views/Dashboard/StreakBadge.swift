import SwiftUI

/// A horizontal badge showing the user's current streaks.
///
/// Displays the combined streak prominently with a fire or milestone emoji,
/// separate focus and hydration streak counts, a gradient border when any
/// streak is active, and a confetti overlay for milestone celebrations.
struct StreakBadge: View {
    /// The streak view model from the environment.
    @Environment(StreakViewModel.self) private var streakVM

    /// Whether the user has Reduce Motion enabled.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether the streak is currently active (any count > 0).
    private var isActive: Bool {
        streakVM.combinedStreak > 0
    }

    /// The emoji to display — milestone emoji when earned, fire otherwise.
    private var displayEmoji: String {
        streakVM.milestoneEmoji ?? "🔥"
    }

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                mainStreakRow
                Divider()
                detailStreaksRow
            }
        }
        .overlay(
            gradientBorder
        )
        .overlay {
            if streakVM.showCelebration {
                ConfettiView(isActive: showCelebrationBinding)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(streakAccessibilityLabel)
    }

    // MARK: - Main Streak Row

    /// The primary row showing the combined streak count with emoji.
    private var mainStreakRow: some View {
        HStack(spacing: 12) {
            Text(displayEmoji)
                .font(.system(size: 36))
                .scaleEffect(isActive ? 1.0 : 0.8)
                .animation(
                    reduceMotion ? .none : .spring(duration: 0.4),
                    value: streakVM.combinedStreak
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    AnimatedCounter(value: streakVM.combinedStreak, font: .title2)
                        .fontWeight(.bold)

                    Text("day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let milestone = streakVM.currentMilestone {
                    Text(milestone)
                        .font(.caption)
                        .foregroundStyle(.electricBlue)
                        .fontWeight(.medium)
                }
            }

            Spacer()
        }
    }

    // MARK: - Detail Streaks Row

    /// Separate focus and hydration streak counts displayed side by side.
    private var detailStreaksRow: some View {
        HStack(spacing: 0) {
            streakDetail(
                icon: "brain.head.profile",
                label: "Focus",
                count: streakVM.focusStreak,
                color: .electricBlue
            )

            Spacer()

            Divider()
                .frame(height: 28)

            Spacer()

            streakDetail(
                icon: "drop.fill",
                label: "Hydration",
                count: streakVM.hydrationStreak,
                color: .aqua
            )
        }
    }

    /// A single streak detail item with icon, label, and count.
    private func streakDetail(
        icon: String,
        label: String,
        count: Int,
        color: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(count) days")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Gradient Border

    /// A subtle gradient border overlay visible when the streak is active.
    private var gradientBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient.accentGradient,
                lineWidth: isActive ? 1.5 : 0
            )
            .opacity(isActive ? 0.6 : 0)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 0.3),
                value: isActive
            )
    }

    // MARK: - Bindings

    /// A binding to drive the confetti view's active state.
    private var showCelebrationBinding: Binding<Bool> {
        @Bindable var vm = streakVM
        return $vm.showCelebration
    }

    // MARK: - Accessibility

    /// Combined accessibility label for the entire badge.
    private var streakAccessibilityLabel: String {
        var parts: [String] = []
        parts.append("Streak badge.")
        parts.append("\(streakVM.combinedStreak) day combined streak.")
        parts.append("\(streakVM.focusStreak) day focus streak.")
        parts.append("\(streakVM.hydrationStreak) day hydration streak.")
        if let milestone = streakVM.currentMilestone {
            parts.append("Milestone: \(milestone).")
        }
        return parts.joined(separator: " ")
    }
}

#Preview {
    StreakBadge()
        .padding()
        .background(Color(.systemGroupedBackground))
        .environment(StreakViewModel())
}
