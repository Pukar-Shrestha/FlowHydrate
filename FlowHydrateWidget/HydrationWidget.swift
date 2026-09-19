import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

/// Timeline entry containing the current state of the hydration tracker.
struct HydrationEntry: TimelineEntry {
    /// The date at which this entry is relevant.
    let date: Date

    /// The current water intake in milliliters.
    let intake: Double

    /// The daily water goal in milliliters.
    let goal: Double

    /// The hydration progress as a value from 0.0 to 1.0.
    let progress: Double
}

// MARK: - Timeline Provider

/// Provides timeline entries for the Hydration Tracker widget.
struct HydrationProvider: TimelineProvider {
    /// Returns a placeholder entry for widget gallery previews.
    func placeholder(in context: Context) -> HydrationEntry {
        HydrationEntry(
            date: .now,
            intake: 1200,
            goal: 2500,
            progress: 0.48
        )
    }

    /// Returns a snapshot entry for quick previews.
    func getSnapshot(in context: Context, completion: @escaping (HydrationEntry) -> Void) {
        let data = SharedDataManager.shared
        let entry = HydrationEntry(
            date: .now,
            intake: data.waterIntake,
            goal: data.waterGoal,
            progress: data.waterProgress
        )
        completion(entry)
    }

    /// Generates a timeline of entries for the widget.
    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationEntry>) -> Void) {
        let data = SharedDataManager.shared
        let entry = HydrationEntry(
            date: .now,
            intake: data.waterIntake,
            goal: data.waterGoal,
            progress: data.waterProgress
        )

        let nextUpdate = Date.now.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

/// The visual presentation of the Hydration Tracker widget.
struct HydrationWidgetView: View {
    /// The timeline entry providing hydration data.
    let entry: HydrationEntry

    /// The formatted intake value in liters (e.g., "1.2L").
    private var formattedIntake: String {
        let liters = entry.intake / 1000.0
        return String(format: "%.1fL", liters)
    }

    /// The formatted goal value in liters (e.g., "2.5L").
    private var formattedGoal: String {
        let liters = entry.goal / 1000.0
        return String(format: "%.1fL", liters)
    }

    /// The progress percentage as an integer (0–100).
    private var percentageText: String {
        "\(Int(entry.progress * 100))%"
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.deepNavy,
                            Color.deepNavy.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 5)

                    Circle()
                        .trim(from: 0, to: CGFloat(min(entry.progress, 1.0)))
                        .stroke(
                            LinearGradient(
                                colors: [Color.aqua, Color.mintGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.aqua)

                        Text(percentageText)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                }
                .frame(width: 80, height: 80)

                Text("\(formattedIntake) / \(formattedGoal)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.aqua.opacity(0.9))
            }
            .padding(8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    /// A text description for VoiceOver accessibility.
    private var accessibilityDescription: String {
        let percentage = Int(entry.progress * 100)
        return "Hydration tracker, \(formattedIntake) of \(formattedGoal), \(percentage) percent complete"
    }
}

// MARK: - Widget Configuration

/// A home screen widget displaying the current water intake progress.
///
/// Shows a circular progress ring with the hydration percentage and
/// intake vs. goal values in an aqua/mint color scheme.
struct HydrationWidget: Widget {
    /// The unique kind identifier for this widget.
    let kind: String = "HydrationWidget"

    /// The widget configuration.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationProvider()) { entry in
            HydrationWidgetView(entry: entry)
        }
        .configurationDisplayName("Hydration Tracker")
        .description("Monitor your daily water intake progress.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview("Hydration Progress", as: .systemSmall) {
    HydrationWidget()
} timeline: {
    HydrationEntry(
        date: .now,
        intake: 1800,
        goal: 2500,
        progress: 0.72
    )
}

#Preview("Hydration Empty", as: .systemSmall) {
    HydrationWidget()
} timeline: {
    HydrationEntry(
        date: .now,
        intake: 0,
        goal: 2500,
        progress: 0.0
    )
}
