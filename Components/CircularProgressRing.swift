import SwiftUI

/// An animated circular progress ring with a neon glow effect.
///
/// This view is the centerpiece of the focus timer, displaying progress
/// as a sweeping arc with a glowing trail. It supports customizable gradients,
/// line widths, sizes, and an optional centered label.
struct CircularProgressRing: View {
    /// The current progress value, clamped between 0.0 and 1.0.
    var progress: Double

    /// The stroke width of the ring.
    var lineWidth: CGFloat

    /// The gradient applied to the progress arc.
    var gradient: LinearGradient

    /// The overall diameter of the ring.
    var size: CGFloat

    /// An optional label displayed at the center of the ring.
    var label: String?

    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Creates a new circular progress ring.
    /// - Parameters:
    ///   - progress: The current progress from 0.0 to 1.0.
    ///   - lineWidth: The stroke width of the ring. Defaults to 12.
    ///   - gradient: The gradient for the progress arc. Defaults to the focus gradient.
    ///   - size: The diameter of the ring. Defaults to 200.
    ///   - label: An optional text label displayed at the center.
    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        gradient: LinearGradient = Color.focusGradient,
        size: CGFloat = 200,
        label: String? = nil
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.size = size
        self.label = label
    }

    /// The clamped progress value ensuring it stays within valid bounds.
    private var clampedProgress: Double {
        min(max(progress, 0.0), 1.0)
    }

    /// The animation style respecting the user's motion preferences.
    private var progressAnimation: Animation {
        if reduceMotion {
            return .linear(duration: 0.3)
        }
        return .spring(response: 0.6, dampingFraction: 0.8)
    }

    var body: some View {
        ZStack {
            backgroundTrack
            glowArc
            progressArc

            if let label {
                Text(label)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(lineWidth + 8)
            }
        }
        .frame(width: size, height: size)
        .animation(progressAnimation, value: clampedProgress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clampedProgress * 100)) percent")
    }

    /// The dimmed background circle track.
    private var backgroundTrack: some View {
        Circle()
            .stroke(Color.deepNavy.opacity(0.3), lineWidth: lineWidth)
    }

    /// A blurred copy of the progress arc creating a neon glow effect.
    private var glowArc: some View {
        Circle()
            .trim(from: 0, to: clampedProgress)
            .stroke(
                gradient,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .blur(radius: 8)
            .opacity(0.5)
    }

    /// The primary progress arc drawn on top of the glow.
    private var progressArc: some View {
        Circle()
            .trim(from: 0, to: clampedProgress)
            .stroke(
                gradient,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
    }
}

#Preview("Progress Ring — Various Levels") {
    VStack(spacing: 32) {
        HStack(spacing: 24) {
            CircularProgressRing(
                progress: 0.25,
                size: 100,
                label: "25%"
            )

            CircularProgressRing(
                progress: 0.5,
                size: 100,
                label: "50%"
            )

            CircularProgressRing(
                progress: 0.75,
                size: 100,
                label: "75%"
            )
        }

        CircularProgressRing(
            progress: 0.85,
            lineWidth: 16,
            size: 220,
            label: "85%"
        )

        CircularProgressRing(
            progress: 1.0,
            gradient: Color.hydrationGradient,
            size: 140,
            label: "Done!"
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
