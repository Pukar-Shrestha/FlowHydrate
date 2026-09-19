import SwiftUI

/// A numeric counter view with smooth rolling-number transitions.
///
/// Displays an integer value using the `.numericText` content transition
/// for a visually appealing digit-roll effect when the value changes.
struct AnimatedCounter: View {
    /// The integer value to display.
    var value: Int

    /// The font used to render the number.
    var font: Font

    /// The color of the displayed number.
    var textColor: Color

    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Creates a new animated counter.
    /// - Parameters:
    ///   - value: The integer value to display.
    ///   - font: The font for the number. Defaults to a large rounded bold style.
    ///   - textColor: The text color. Defaults to `.primary`.
    init(
        value: Int,
        font: Font = .system(size: 60, weight: .bold, design: .rounded),
        textColor: Color = .primary
    ) {
        self.value = value
        self.font = font
        self.textColor = textColor
    }

    /// The animation style respecting motion preferences.
    private var counterAnimation: Animation {
        if reduceMotion {
            return .linear(duration: 0.2)
        }
        return .spring(response: 0.4, dampingFraction: 0.9)
    }

    var body: some View {
        Text("\(value)")
            .font(font)
            .monospacedDigit()
            .foregroundStyle(textColor)
            .contentTransition(.numericText(countsDown: true))
            .animation(counterAnimation, value: value)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(value)")
    }
}

/// A time display view that formats seconds as MM:SS with smooth rolling transitions.
///
/// Designed for timer displays, this view presents a `TimeInterval` as a
/// minutes-and-seconds string with individual digit-roll animations.
struct AnimatedTimeDisplay: View {
    /// The time interval in seconds to display.
    var seconds: TimeInterval

    /// The font used to render the time.
    var font: Font

    /// The color of the displayed time.
    var textColor: Color

    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Creates a new animated time display.
    /// - Parameters:
    ///   - seconds: The time interval in seconds.
    ///   - font: The font for the time display. Defaults to a large rounded bold style.
    ///   - textColor: The text color. Defaults to `.primary`.
    init(
        seconds: TimeInterval,
        font: Font = .system(size: 60, weight: .bold, design: .rounded),
        textColor: Color = .primary
    ) {
        self.seconds = seconds
        self.font = font
        self.textColor = textColor
    }

    /// The total whole minutes in the time interval.
    private var minutes: Int {
        Int(max(seconds, 0)) / 60
    }

    /// The remaining whole seconds after extracting minutes.
    private var remainingSeconds: Int {
        Int(max(seconds, 0)) % 60
    }

    /// The formatted MM:SS string.
    private var formattedTime: String {
        String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    /// The accessible description of the remaining time.
    private var accessibilityDescription: String {
        var parts: [String] = []
        if minutes > 0 {
            parts.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }
        if remainingSeconds > 0 || minutes == 0 {
            parts.append("\(remainingSeconds) \(remainingSeconds == 1 ? "second" : "seconds")")
        }
        return parts.joined(separator: " ") + " remaining"
    }

    /// The animation style respecting motion preferences.
    private var counterAnimation: Animation {
        if reduceMotion {
            return .linear(duration: 0.2)
        }
        return .spring(response: 0.4, dampingFraction: 0.9)
    }

    var body: some View {
        Text(formattedTime)
            .font(font)
            .monospacedDigit()
            .foregroundStyle(textColor)
            .contentTransition(.numericText(countsDown: true))
            .animation(counterAnimation, value: seconds)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)
    }
}

#Preview("Animated Counter") {
    struct CounterPreview: View {
        @State private var count = 42

        var body: some View {
            VStack(spacing: 32) {
                AnimatedCounter(value: count)

                AnimatedCounter(
                    value: count,
                    font: .system(size: 32, weight: .semibold, design: .rounded),
                    textColor: .electricBlue
                )

                HStack(spacing: 20) {
                    Button("−") { count = max(0, count - 1) }
                        .font(.title)
                    Button("+") { count += 1 }
                        .font(.title)
                }
            }
            .padding()
        }
    }
    return CounterPreview()
}

#Preview("Animated Time Display") {
    struct TimePreview: View {
        @State private var remaining: TimeInterval = 1500

        var body: some View {
            VStack(spacing: 32) {
                AnimatedTimeDisplay(seconds: remaining)

                AnimatedTimeDisplay(
                    seconds: remaining,
                    font: .system(size: 36, weight: .bold, design: .rounded),
                    textColor: .aqua
                )

                HStack(spacing: 20) {
                    Button("−60s") { remaining = max(0, remaining - 60) }
                    Button("−1s") { remaining = max(0, remaining - 1) }
                    Button("+1s") { remaining += 1 }
                    Button("+60s") { remaining += 60 }
                }
            }
            .padding()
        }
    }
    return TimePreview()
}
