import SwiftUI

/// A dashboard card displaying today's focus session progress.
///
/// Shows a small circular progress ring alongside animated counters for
/// total focus minutes and completed sessions. Tappable to navigate
/// to the Focus tab.
struct FocusSummaryCard: View {
    /// Total minutes focused today.
    let focusMinutes: Int

    /// Number of focus sessions completed today.
    let sessionsCompleted: Int

    /// The assumed daily focus target in minutes used to compute progress.
    private let targetMinutes: Double = 100

    /// Computed progress as a fraction of the daily target (0…1).
    private var progress: Double {
        guard targetMinutes > 0 else { return 0 }
        return min(Double(focusMinutes) / targetMinutes, 1.0)
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                CircularProgressRing(
                    progress: progress,
                    lineWidth: 6,
                    gradient: .focusGradient,
                    size: 60
                )
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        AnimatedCounter(value: focusMinutes, font: .headline)
                        Text("min")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(sessionsCompleted) session\(sessionsCompleted == 1 ? "" : "s") completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Focus summary. \(focusMinutes) minutes focused today. \(sessionsCompleted) session\(sessionsCompleted == 1 ? "" : "s") completed."
        )
        .accessibilityValue("\(Int(progress * 100)) percent of daily goal")
        .accessibilityHint("Tap to view the focus timer")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Default") {
    VStack(spacing: 16) {
        FocusSummaryCard(focusMinutes: 45, sessionsCompleted: 2)
        FocusSummaryCard(focusMinutes: 100, sessionsCompleted: 4)
        FocusSummaryCard(focusMinutes: 0, sessionsCompleted: 0)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
