import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

/// Timeline entry combining both focus timer and hydration tracker state.
struct CombinedEntry: TimelineEntry {
    /// The date at which this entry is relevant.
    let date: Date

    // Focus data

    /// The number of seconds remaining in the current focus session.
    let focusRemainingSeconds: Int

    /// The total number of seconds for the current focus session.
    let focusTotalSeconds: Int

    /// The focus session progress as a value from 0.0 to 1.0.
    let focusProgress: Double

    /// The display name of the current timer mode.
    let focusModeName: String

    /// Whether the focus timer is currently running.
    let isFocusRunning: Bool

    // Hydration data

    /// The current water intake in milliliters.
    let waterIntake: Double

    /// The daily water goal in milliliters.
    let waterGoal: Double

    /// The hydration progress as a value from 0.0 to 1.0.
    let waterProgress: Double
}

// MARK: - Timeline Provider

/// Provides timeline entries for the Combined Focus + Hydration widget.
struct CombinedProvider: TimelineProvider {
    /// Returns a placeholder entry for widget gallery previews.
    func placeholder(in context: Context) -> CombinedEntry {
        CombinedEntry(
            date: .now,
            focusRemainingSeconds: 1500,
            focusTotalSeconds: 1500,
            focusProgress: 0.0,
            focusModeName: "Focus",
            isFocusRunning: false,
            waterIntake: 1200,
            waterGoal: 2500,
            waterProgress: 0.48
        )
    }

    /// Returns a snapshot entry for quick previews.
    func getSnapshot(in context: Context, completion: @escaping (CombinedEntry) -> Void) {
        completion(buildEntry())
    }

    /// Generates a timeline of entries for the widget.
    func getTimeline(in context: Context, completion: @escaping (Timeline<CombinedEntry>) -> Void) {
        let entry = buildEntry()
        let data = SharedDataManager.shared
        let refreshInterval: TimeInterval = data.isFocusRunning ? 60 : 900
        let nextUpdate = Date.now.addingTimeInterval(refreshInterval)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// Reads current data from the shared data manager and builds an entry.
    private func buildEntry() -> CombinedEntry {
        let data = SharedDataManager.shared
        return CombinedEntry(
            date: .now,
            focusRemainingSeconds: data.focusRemainingSeconds,
            focusTotalSeconds: max(data.focusTotalSeconds, 1),
            focusProgress: data.focusProgress,
            focusModeName: displayName(for: data.focusModeRaw),
            isFocusRunning: data.isFocusRunning,
            waterIntake: data.waterIntake,
            waterGoal: data.waterGoal,
            waterProgress: data.waterProgress
        )
    }

    /// Maps a raw timer mode string to its display name.
    private func displayName(for modeRaw: String) -> String {
        switch modeRaw {
        case "focus": return "Focus"
        case "shortBreak": return "Short Break"
        case "longBreak": return "Long Break"
        default: return "Focus"
        }
    }
}

// MARK: - Widget View

/// The visual presentation of the Combined Focus + Hydration widget.
struct CombinedWidgetView: View {
    /// The timeline entry providing combined data.
    let entry: CombinedEntry

    /// The formatted remaining focus time in MM:SS format.
    private var focusTimeText: String {
        let minutes = entry.focusRemainingSeconds / 60
        let seconds = entry.focusRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// The color associated with the current timer mode.
    private var focusModeColor: Color {
        switch entry.focusModeName {
        case "Short Break": return .mintGreen
        case "Long Break": return .aqua
        default: return .electricBlue
        }
    }

    /// The formatted water intake in liters.
    private var intakeText: String {
        String(format: "%.1fL", entry.waterIntake / 1000.0)
    }

    /// The formatted water goal in liters.
    private var goalText: String {
        String(format: "%.1fL", entry.waterGoal / 1000.0)
    }

    /// The hydration percentage as an integer.
    private var hydrationPercentage: Int {
        Int(entry.waterProgress * 100)
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [Color.deepNavy, Color.deepNavy.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    ContainerRelativeShape()
                        .fill(.ultraThinMaterial.opacity(0.3))
                )

            HStack(spacing: 0) {
                focusSection
                    .frame(maxWidth: .infinity)

                Divider()
                    .frame(width: 1)
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 16)

                hydrationSection
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    /// The focus timer section displayed on the left side.
    private var focusSection: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: CGFloat(entry.focusProgress))
                    .stroke(
                        focusModeColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                if entry.isFocusRunning {
                    Text(focusTimeText)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundStyle(focusModeColor)
                }
            }
            .frame(width: 56, height: 56)

            Text(entry.isFocusRunning ? entry.focusModeName : "Ready")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(focusModeColor)
                .lineLimit(1)
        }
    }

    /// The hydration tracker section displayed on the right side.
    private var hydrationSection: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: CGFloat(min(entry.waterProgress, 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [Color.aqua, Color.mintGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.aqua)

                    Text("\(hydrationPercentage)%")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }
            .frame(width: 56, height: 56)

            Text("\(intakeText)/\(goalText)")
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(Color.aqua.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    /// A text description for VoiceOver accessibility.
    private var accessibilityDescription: String {
        let focusStatus: String
        if entry.isFocusRunning {
            let minutes = entry.focusRemainingSeconds / 60
            let seconds = entry.focusRemainingSeconds % 60
            focusStatus = "\(entry.focusModeName) timer, \(minutes) minutes \(seconds) seconds remaining"
        } else {
            focusStatus = "Focus timer ready"
        }

        let hydrationStatus = "Hydration \(hydrationPercentage) percent, \(intakeText) of \(goalText)"

        return "\(focusStatus). \(hydrationStatus)"
    }
}

// MARK: - Widget Configuration

/// A medium home screen widget showing both focus timer and hydration tracker side by side.
///
/// Displays the focus progress ring with time/status on the left and
/// the hydration progress ring with intake on the right, separated by a divider.
struct CombinedWidget: Widget {
    /// The unique kind identifier for this widget.
    let kind: String = "CombinedWidget"

    /// The widget configuration.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CombinedProvider()) { entry in
            CombinedWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus & Hydration")
        .description("Track both your focus sessions and water intake.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview("Combined Running", as: .systemMedium) {
    CombinedWidget()
} timeline: {
    CombinedEntry(
        date: .now,
        focusRemainingSeconds: 1234,
        focusTotalSeconds: 1500,
        focusProgress: 0.65,
        focusModeName: "Focus",
        isFocusRunning: true,
        waterIntake: 1800,
        waterGoal: 2500,
        waterProgress: 0.72
    )
}

#Preview("Combined Idle", as: .systemMedium) {
    CombinedWidget()
} timeline: {
    CombinedEntry(
        date: .now,
        focusRemainingSeconds: 0,
        focusTotalSeconds: 1500,
        focusProgress: 0.0,
        focusModeName: "Focus",
        isFocusRunning: false,
        waterIntake: 500,
        waterGoal: 2500,
        waterProgress: 0.2
    )
}
