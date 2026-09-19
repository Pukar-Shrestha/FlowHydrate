import SwiftUI

/// A dashboard card displaying today's hydration intake versus the daily goal.
///
/// Shows a small circular progress ring alongside the current intake in liters,
/// the daily goal, and a percentage indicator. Tappable to navigate to the
/// Hydration tab.
struct HydrationSummaryCard: View {
    /// Current water intake in milliliters for today.
    let currentIntake: Double

    /// Daily water intake goal in milliliters.
    let dailyGoal: Double

    /// Computed progress as a fraction of the daily goal (0…1).
    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(currentIntake / dailyGoal, 1.0)
    }

    /// Current intake formatted in liters.
    private var currentLiters: String {
        String(format: "%.1f", currentIntake / 1000)
    }

    /// Daily goal formatted in liters.
    private var goalLiters: String {
        String(format: "%.1f", dailyGoal / 1000)
    }

    /// Progress expressed as an integer percentage.
    private var percentageText: String {
        "\(Int(progress * 100))%"
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                CircularProgressRing(
                    progress: progress,
                    lineWidth: 6,
                    gradient: .hydrationGradient,
                    size: 60
                )
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Hydration")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(currentLiters)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("/")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(goalLiters) L")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(percentageText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(progress >= 1.0 ? .green : .secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Hydration summary. \(currentLiters) of \(goalLiters) liters consumed today."
        )
        .accessibilityValue("\(percentageText) of daily goal")
        .accessibilityHint("Tap to view the hydration tracker")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Various States") {
    VStack(spacing: 16) {
        HydrationSummaryCard(currentIntake: 1500, dailyGoal: 2500)
        HydrationSummaryCard(currentIntake: 2500, dailyGoal: 2500)
        HydrationSummaryCard(currentIntake: 0, dailyGoal: 3000)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
