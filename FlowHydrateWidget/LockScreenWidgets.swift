import WidgetKit
import SwiftUI

// MARK: - Focus Lock Screen Entries & Provider

/// Timeline entry for the Focus Lock Screen widget.
struct FocusLockScreenEntry: TimelineEntry {
    /// The date at which this entry is relevant.
    let date: Date

    /// The number of seconds remaining in the current focus session.
    let remainingSeconds: Int

    /// The focus session progress as a value from 0.0 to 1.0.
    let progress: Double

    /// The display name of the current timer mode.
    let modeName: String

    /// Whether the focus timer is currently running.
    let isRunning: Bool
}

/// Provides timeline entries for the Focus Lock Screen widget.
struct FocusLockScreenProvider: TimelineProvider {
    /// Returns a placeholder entry for widget gallery previews.
    func placeholder(in context: Context) -> FocusLockScreenEntry {
        FocusLockScreenEntry(
            date: .now,
            remainingSeconds: 1500,
            progress: 0.0,
            modeName: "Focus",
            isRunning: false
        )
    }

    /// Returns a snapshot entry for quick previews.
    func getSnapshot(in context: Context, completion: @escaping (FocusLockScreenEntry) -> Void) {
        completion(buildEntry())
    }

    /// Generates a timeline of entries for the widget.
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusLockScreenEntry>) -> Void) {
        let entry = buildEntry()
        let data = SharedDataManager.shared
        let refreshInterval: TimeInterval = data.isFocusRunning ? 60 : 900
        let nextUpdate = Date.now.addingTimeInterval(refreshInterval)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// Reads current data from the shared data manager and builds an entry.
    private func buildEntry() -> FocusLockScreenEntry {
        let data = SharedDataManager.shared
        return FocusLockScreenEntry(
            date: .now,
            remainingSeconds: data.focusRemainingSeconds,
            progress: data.focusProgress,
            modeName: displayName(for: data.focusModeRaw),
            isRunning: data.isFocusRunning
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

// MARK: - Hydration Lock Screen Entries & Provider

/// Timeline entry for the Hydration Lock Screen widget.
struct HydrationLockScreenEntry: TimelineEntry {
    /// The date at which this entry is relevant.
    let date: Date

    /// The current water intake in milliliters.
    let intake: Double

    /// The daily water goal in milliliters.
    let goal: Double

    /// The hydration progress as a value from 0.0 to 1.0.
    let progress: Double
}

/// Provides timeline entries for the Hydration Lock Screen widget.
struct HydrationLockScreenProvider: TimelineProvider {
    /// Returns a placeholder entry for widget gallery previews.
    func placeholder(in context: Context) -> HydrationLockScreenEntry {
        HydrationLockScreenEntry(
            date: .now,
            intake: 1200,
            goal: 2500,
            progress: 0.48
        )
    }

    /// Returns a snapshot entry for quick previews.
    func getSnapshot(in context: Context, completion: @escaping (HydrationLockScreenEntry) -> Void) {
        completion(buildEntry())
    }

    /// Generates a timeline of entries for the widget.
    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationLockScreenEntry>) -> Void) {
        let entry = buildEntry()
        let nextUpdate = Date.now.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// Reads current data from the shared data manager and builds an entry.
    private func buildEntry() -> HydrationLockScreenEntry {
        let data = SharedDataManager.shared
        return HydrationLockScreenEntry(
            date: .now,
            intake: data.waterIntake,
            goal: data.waterGoal,
            progress: data.waterProgress
        )
    }
}

// MARK: - Focus Lock Screen Views

/// Circular gauge view for the focus timer on the Lock Screen.
struct FocusCircularView: View {
    /// The timeline entry providing focus timer data.
    let entry: FocusLockScreenEntry

    var body: some View {
        Gauge(value: entry.progress, in: 0...1) {
            Image(systemName: "timer")
                .accessibilityLabel("Focus timer")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(entry.isRunning ? .blue : .gray)
        .accessibilityLabel(circularAccessibilityLabel)
    }

    /// Accessibility label for the circular gauge.
    private var circularAccessibilityLabel: String {
        if entry.isRunning {
            let minutes = entry.remainingSeconds / 60
            return "Focus timer, \(minutes) minutes remaining, \(Int(entry.progress * 100)) percent complete"
        } else {
            return "Focus timer idle"
        }
    }
}

/// Rectangular view for the focus timer on the Lock Screen.
struct FocusRectangularView: View {
    /// The timeline entry providing focus timer data.
    let entry: FocusLockScreenEntry

    /// The formatted remaining time in MM:SS format.
    private var formattedTime: String {
        let minutes = entry.remainingSeconds / 60
        let seconds = entry.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.title3)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.modeName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if entry.isRunning {
                    Text(formattedTime)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .monospacedDigit()
                } else {
                    Text("Ready")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rectangularAccessibilityLabel)
    }

    /// Accessibility label for the rectangular view.
    private var rectangularAccessibilityLabel: String {
        if entry.isRunning {
            let minutes = entry.remainingSeconds / 60
            let seconds = entry.remainingSeconds % 60
            return "\(entry.modeName), \(minutes) minutes and \(seconds) seconds remaining"
        } else {
            return "\(entry.modeName) timer ready"
        }
    }
}

// MARK: - Hydration Lock Screen Views

/// Circular gauge view for the hydration tracker on the Lock Screen.
struct HydrationCircularView: View {
    /// The timeline entry providing hydration data.
    let entry: HydrationLockScreenEntry

    var body: some View {
        Gauge(value: min(entry.progress, 1.0), in: 0...1) {
            Image(systemName: "drop.fill")
                .accessibilityLabel("Water intake")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(.cyan)
        .accessibilityLabel("Hydration \(Int(entry.progress * 100)) percent complete")
    }
}

/// Rectangular view for the hydration tracker on the Lock Screen.
struct HydrationRectangularView: View {
    /// The timeline entry providing hydration data.
    let entry: HydrationLockScreenEntry

    /// The formatted intake value in liters.
    private var intakeText: String {
        String(format: "%.1fL", entry.intake / 1000.0)
    }

    /// The formatted goal value in liters.
    private var goalText: String {
        String(format: "%.1fL", entry.goal / 1000.0)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "drop.fill")
                .font(.title3)
                .foregroundStyle(.cyan)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Hydration")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(intakeText) / \(goalText)")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hydration, \(intakeText) of \(goalText), \(Int(entry.progress * 100)) percent")
    }
}

// MARK: - Focus Lock Screen Widget

/// A Lock Screen widget displaying focus timer progress.
///
/// Supports circular and rectangular accessory families, showing a gauge
/// or mode name with remaining time respectively.
struct FocusLockScreenWidget: Widget {
    /// The unique kind identifier for this widget.
    let kind: String = "FocusLockScreenWidget"

    /// The widget configuration.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusLockScreenProvider()) { entry in
            switch entry.widgetFamily {
            case .accessoryCircular:
                FocusCircularView(entry: entry)
            case .accessoryRectangular:
                FocusRectangularView(entry: entry)
            default:
                FocusCircularView(entry: entry)
            }
        }
        .configurationDisplayName("Focus Timer")
        .description("Quick view of your focus session on the Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Hydration Lock Screen Widget

/// A Lock Screen widget displaying hydration progress.
///
/// Supports circular and rectangular accessory families, showing a gauge
/// or intake/goal text respectively.
struct HydrationLockScreenWidget: Widget {
    /// The unique kind identifier for this widget.
    let kind: String = "HydrationLockScreenWidget"

    /// The widget configuration.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationLockScreenProvider()) { entry in
            switch entry.widgetFamily {
            case .accessoryCircular:
                HydrationCircularView(entry: entry)
            case .accessoryRectangular:
                HydrationRectangularView(entry: entry)
            default:
                HydrationCircularView(entry: entry)
            }
        }
        .configurationDisplayName("Hydration Tracker")
        .description("Quick view of your water intake on the Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Environment Extension

/// Extension to access the widget family from the environment in Lock Screen widget views.
private extension TimelineEntry {
    /// The current widget family from the shared widget rendering context.
    var widgetFamily: WidgetFamily {
        // WidgetKit automatically selects the correct family view;
        // this property is resolved at runtime by the system.
        // We use @Environment(\.widgetFamily) in wrapper views instead.
        .accessoryCircular
    }
}

// MARK: - Family-Aware Wrapper Views

/// A wrapper view that selects the appropriate Focus Lock Screen layout based on widget family.
struct FocusLockScreenContentView: View {
    /// The current widget family.
    @Environment(\.widgetFamily) var widgetFamily

    /// The timeline entry providing focus timer data.
    let entry: FocusLockScreenEntry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            FocusCircularView(entry: entry)
        case .accessoryRectangular:
            FocusRectangularView(entry: entry)
        default:
            FocusCircularView(entry: entry)
        }
    }
}

/// A wrapper view that selects the appropriate Hydration Lock Screen layout based on widget family.
struct HydrationLockScreenContentView: View {
    /// The current widget family.
    @Environment(\.widgetFamily) var widgetFamily

    /// The timeline entry providing hydration data.
    let entry: HydrationLockScreenEntry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            HydrationCircularView(entry: entry)
        case .accessoryRectangular:
            HydrationRectangularView(entry: entry)
        default:
            HydrationCircularView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview("Focus Circular", as: .accessoryCircular) {
    FocusLockScreenWidget()
} timeline: {
    FocusLockScreenEntry(
        date: .now,
        remainingSeconds: 1234,
        progress: 0.65,
        modeName: "Focus",
        isRunning: true
    )
}

#Preview("Focus Rectangular", as: .accessoryRectangular) {
    FocusLockScreenWidget()
} timeline: {
    FocusLockScreenEntry(
        date: .now,
        remainingSeconds: 1234,
        progress: 0.65,
        modeName: "Focus",
        isRunning: true
    )
}

#Preview("Hydration Circular", as: .accessoryCircular) {
    HydrationLockScreenWidget()
} timeline: {
    HydrationLockScreenEntry(
        date: .now,
        intake: 1800,
        goal: 2500,
        progress: 0.72
    )
}

#Preview("Hydration Rectangular", as: .accessoryRectangular) {
    HydrationLockScreenWidget()
} timeline: {
    HydrationLockScreenEntry(
        date: .now,
        intake: 1800,
        goal: 2500,
        progress: 0.72
    )
}
