import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

/// Timeline entry containing the current state of the focus timer.
struct FocusEntry: TimelineEntry {
    /// The date at which this entry is relevant.
    let date: Date

    /// The number of seconds remaining in the current focus session.
    let remainingSeconds: Int

    /// The total number of seconds for the current focus session.
    let totalSeconds: Int

    /// The progress of the current session as a value from 0.0 to 1.0.
    let progress: Double

    /// The display name of the current timer mode.
    let modeName: String

    /// Whether the focus timer is currently running.
    let isRunning: Bool
}

// MARK: - Timeline Provider

/// Provides timeline entries for the Focus Timer widget.
struct FocusProvider: TimelineProvider {
    /// Returns a placeholder entry for widget gallery previews.
    func placeholder(in context: Context) -> FocusEntry {
        FocusEntry(
            date: .now,
            remainingSeconds: 1500,
            totalSeconds: 1500,
            progress: 0.0,
            modeName: "Focus",
            isRunning: false
        )
    }

    /// Returns a snapshot entry for quick previews.
    func getSnapshot(in context: Context, completion: @escaping (FocusEntry) -> Void) {
        let data = SharedDataManager.shared
        let entry = FocusEntry(
            date: .now,
            remainingSeconds: data.focusRemainingSeconds,
            totalSeconds: max(data.focusTotalSeconds, 1),
            progress: data.focusProgress,
            modeName: displayName(for: data.focusModeRaw),
            isRunning: data.isFocusRunning
        )
        completion(entry)
    }

    /// Generates a timeline of entries for the widget.
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusEntry>) -> Void) {
        let data = SharedDataManager.shared
        let entry = FocusEntry(
            date: .now,
            remainingSeconds: data.focusRemainingSeconds,
            totalSeconds: max(data.focusTotalSeconds, 1),
            progress: data.focusProgress,
            modeName: displayName(for: data.focusModeRaw),
            isRunning: data.isFocusRunning
        )

        let refreshInterval: TimeInterval = data.isFocusRunning ? 60 : 900
        let nextUpdate = Date.now.addingTimeInterval(refreshInterval)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
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

/// The visual presentation of the Focus Timer widget.
struct FocusWidgetView: View {
    /// The timeline entry providing focus timer data.
    let entry: FocusEntry

    /// The formatted remaining time string in MM:SS format.
    private var formattedTime: String {
        let minutes = entry.remainingSeconds / 60
        let seconds = entry.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// The color associated with the current timer mode.
    private var modeColor: Color {
        switch entry.modeName {
        case "Short Break": return .mintGreen
        case "Long Break": return .aqua
        default: return .electricBlue
        }
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

            if entry.isRunning {
                runningContent
            } else {
                idleContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    /// Content displayed when the focus timer is actively running.
    private var runningContent: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: CGFloat(entry.progress))
                    .stroke(
                        modeColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(formattedTime)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .frame(width: 80, height: 80)

            Text(entry.modeName)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(modeColor)
                .textCase(.uppercase)
        }
        .padding(8)
    }

    /// Content displayed when the focus timer is idle.
    private var idleContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 32))
                .foregroundStyle(Color.electricBlue)

            Text("Ready to Focus")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }

    /// A text description for VoiceOver accessibility.
    private var accessibilityDescription: String {
        if entry.isRunning {
            let minutes = entry.remainingSeconds / 60
            let seconds = entry.remainingSeconds % 60
            return "\(entry.modeName) timer running, \(minutes) minutes and \(seconds) seconds remaining"
        } else {
            return "Focus timer ready to start"
        }
    }
}

// MARK: - Widget Configuration

/// A home screen widget displaying the current focus timer status.
///
/// Shows the remaining time and progress ring when a session is active,
/// or an idle state prompt when no session is running.
struct FocusWidget: Widget {
    /// The unique kind identifier for this widget.
    let kind: String = "FocusWidget"

    /// The widget configuration.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusProvider()) { entry in
            FocusWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Timer")
        .description("Track your focus session progress at a glance.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview("Focus Running", as: .systemSmall) {
    FocusWidget()
} timeline: {
    FocusEntry(
        date: .now,
        remainingSeconds: 1234,
        totalSeconds: 1500,
        progress: 0.65,
        modeName: "Focus",
        isRunning: true
    )
}

#Preview("Focus Idle", as: .systemSmall) {
    FocusWidget()
} timeline: {
    FocusEntry(
        date: .now,
        remainingSeconds: 0,
        totalSeconds: 1500,
        progress: 0.0,
        modeName: "Focus",
        isRunning: false
    )
}
