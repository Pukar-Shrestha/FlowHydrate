import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Lock Screen Live Activity View

/// The Lock Screen and banner presentation for the focus timer Live Activity.
///
/// Displays a horizontal layout with mode icon, session name, progress bar,
/// and remaining time using mode-specific colors.
struct LockScreenLiveActivityView: View {
    /// The Live Activity context containing attributes and content state.
    let context: ActivityViewContext<FlowHydrateActivityAttributes>

    /// The formatted remaining time in MM:SS format.
    private var formattedTime: String {
        let minutes = context.state.remainingSeconds / 60
        let seconds = context.state.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// The color associated with the current timer mode.
    private var modeColor: Color {
        switch context.state.modeName {
        case "Short Break": return .mintGreen
        case "Long Break": return .aqua
        default: return .electricBlue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: context.state.modeIcon)
                .font(.title2)
                .foregroundStyle(modeColor)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.sessionName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                ProgressView(value: context.state.progress, total: 1.0)
                    .tint(modeColor)
                    .accessibilityLabel("Session progress")
                    .accessibilityValue("\(Int(context.state.progress * 100)) percent")
            }

            Spacer(minLength: 0)

            Text(formattedTime)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(modeColor)
                .accessibilityLabel("\(context.state.remainingSeconds / 60) minutes \(context.state.remainingSeconds % 60) seconds remaining")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.deepNavy.gradient)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(lockScreenAccessibilityLabel)
    }

    /// A combined accessibility label for the entire lock screen view.
    private var lockScreenAccessibilityLabel: String {
        let minutes = context.state.remainingSeconds / 60
        let seconds = context.state.remainingSeconds % 60
        return "\(context.attributes.sessionName), \(context.state.modeName), \(minutes) minutes \(seconds) seconds remaining, \(Int(context.state.progress * 100)) percent complete"
    }
}

// MARK: - Dynamic Island Expanded View

/// The expanded Dynamic Island content for the focus timer Live Activity.
struct DynamicIslandExpandedContent: View {
    /// The Live Activity context containing attributes and content state.
    let context: ActivityViewContext<FlowHydrateActivityAttributes>

    /// The formatted remaining time in MM:SS format.
    private var formattedTime: String {
        let minutes = context.state.remainingSeconds / 60
        let seconds = context.state.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// The color associated with the current timer mode.
    private var modeColor: Color {
        switch context.state.modeName {
        case "Short Break": return .mintGreen
        case "Long Break": return .aqua
        default: return .electricBlue
        }
    }

    /// The progress ring view for the expanded Dynamic Island.
    var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: CGFloat(context.state.progress))
                .stroke(
                    modeColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: context.state.modeIcon)
                .font(.caption)
                .foregroundStyle(modeColor)
        }
        .frame(width: 36, height: 36)
        .accessibilityLabel("Progress \(Int(context.state.progress * 100)) percent")
    }

    /// The time and mode details view.
    var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formattedTime)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(context.state.modeName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(modeColor)
        }
    }
}

// MARK: - Focus Live Activity Widget

/// A Widget that presents the focus timer as a Live Activity on the Dynamic Island and Lock Screen.
///
/// Handles all presentation regions: Lock Screen banner, Dynamic Island expanded,
/// compact leading/trailing, and minimal states.
struct FocusLiveActivity: Widget {
    /// The widget body defining the activity configuration.
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlowHydrateActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedProgressRing(for: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    expandedTimeDisplay(for: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomBar(for: context)
                }

                DynamicIslandExpandedRegion(.center) {
                    expandedCenterLabel(for: context)
                }
            } compactLeading: {
                Image(systemName: context.state.modeIcon)
                    .font(.caption)
                    .foregroundStyle(modeColor(for: context.state.modeName))
                    .accessibilityLabel(context.state.modeName)
            } compactTrailing: {
                Text(formattedTime(for: context.state.remainingSeconds))
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(modeColor(for: context.state.modeName))
                    .accessibilityLabel(timeAccessibilityLabel(for: context.state.remainingSeconds))
            } minimal: {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)

                    Circle()
                        .trim(from: 0, to: CGFloat(context.state.progress))
                        .stroke(
                            modeColor(for: context.state.modeName),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .padding(2)
                .accessibilityLabel("Focus timer \(Int(context.state.progress * 100)) percent")
            }
        }
    }

    // MARK: - Expanded Region Builders

    /// The progress ring shown in the leading expanded region.
    @ViewBuilder
    private func expandedProgressRing(for context: ActivityViewContext<FlowHydrateActivityAttributes>) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: CGFloat(context.state.progress))
                .stroke(
                    modeColor(for: context.state.modeName),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: context.state.modeIcon)
                .font(.caption)
                .foregroundStyle(modeColor(for: context.state.modeName))
        }
        .frame(width: 40, height: 40)
        .accessibilityLabel("Progress \(Int(context.state.progress * 100)) percent")
    }

    /// The time display shown in the trailing expanded region.
    @ViewBuilder
    private func expandedTimeDisplay(for context: ActivityViewContext<FlowHydrateActivityAttributes>) -> some View {
        Text(formattedTime(for: context.state.remainingSeconds))
            .font(.system(.title3, design: .rounded, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .accessibilityLabel(timeAccessibilityLabel(for: context.state.remainingSeconds))
    }

    /// The bottom bar showing a progress indicator.
    @ViewBuilder
    private func expandedBottomBar(for context: ActivityViewContext<FlowHydrateActivityAttributes>) -> some View {
        ProgressView(value: context.state.progress, total: 1.0)
            .tint(modeColor(for: context.state.modeName))
            .accessibilityLabel("Session progress")
            .accessibilityValue("\(Int(context.state.progress * 100)) percent")
    }

    /// The center label showing the session name and mode.
    @ViewBuilder
    private func expandedCenterLabel(for context: ActivityViewContext<FlowHydrateActivityAttributes>) -> some View {
        VStack(spacing: 2) {
            Text(context.attributes.sessionName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(context.state.modeName)
                .font(.caption2)
                .foregroundStyle(modeColor(for: context.state.modeName))
        }
    }

    // MARK: - Helpers

    /// Returns the color associated with a timer mode name.
    private func modeColor(for modeName: String) -> Color {
        switch modeName {
        case "Short Break": return .mintGreen
        case "Long Break": return .aqua
        default: return .electricBlue
        }
    }

    /// Formats a time duration in seconds to MM:SS.
    private func formattedTime(for seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    /// Returns an accessibility label for a time duration in seconds.
    private func timeAccessibilityLabel(for seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return "\(minutes) minutes \(secs) seconds remaining"
    }
}

// MARK: - Previews

#Preview("Lock Screen Live Activity", as: .content, using: FlowHydrateActivityAttributes(
    sessionName: "Focus Session",
    totalSeconds: 1500,
    startTime: .now
)) {
    FocusLiveActivity()
} contentStates: {
    FlowHydrateActivityAttributes.ContentState(
        remainingSeconds: 1234,
        progress: 0.65,
        modeName: "Focus",
        modeIcon: "brain.head.profile"
    )
    FlowHydrateActivityAttributes.ContentState(
        remainingSeconds: 300,
        progress: 0.8,
        modeName: "Short Break",
        modeIcon: "cup.and.saucer.fill"
    )
}
