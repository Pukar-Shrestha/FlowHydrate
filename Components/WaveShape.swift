import SwiftUI

/// An animated sine-wave shape used for the water-fill visualization.
///
/// Draws a sine wave at a vertical position determined by `progress`,
/// filling downward to create a water-level effect. Both `progress` and
/// `offset` are animatable, enabling smooth fill-level transitions and
/// continuous wave motion.
struct WaveShape: Shape {
    /// The fill level from 0.0 (empty) to 1.0 (full).
    var progress: Double

    /// The peak-to-trough height of the sine wave in points.
    var waveHeight: Double

    /// The horizontal phase offset for animating wave motion.
    var offset: Double

    /// The animatable data pair enabling SwiftUI to interpolate both properties.
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(progress, offset) }
        set {
            progress = newValue.first
            offset = newValue.second
        }
    }

    /// Creates a new wave shape.
    /// - Parameters:
    ///   - progress: The fill level from 0.0 to 1.0.
    ///   - waveHeight: The amplitude of the sine wave. Defaults to 10.
    ///   - offset: The phase offset for animation. Defaults to 0.
    init(progress: Double, waveHeight: Double = 10, offset: Double = 0) {
        self.progress = progress
        self.waveHeight = waveHeight
        self.offset = offset
    }

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0.0), 1.0)
        let waterY = rect.height * (1.0 - clampedProgress)
        let frequency = 2.0 * .pi * 2.0 / rect.width

        var path = Path()

        path.move(to: CGPoint(x: 0, y: waterY))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sineValue = sin(relativeX * 2.0 * .pi * 2.0 + offset)
            let y = waterY + sineValue * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

/// A view that clips its content to an animated wave shape, creating a water-fill effect.
///
/// Continuously animates the wave offset for a flowing water appearance.
/// The fill level can be animated independently by changing `progress`.
struct WaterFillView: View {
    /// The fill level from 0.0 (empty) to 1.0 (full).
    var progress: Double

    /// The gradient applied to the water fill.
    var gradient: LinearGradient

    /// The amplitude of the wave oscillation.
    var waveHeight: Double

    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The continuously incrementing wave phase offset.
    @State private var waveOffset: Double = 0.0

    /// Creates a new water fill view.
    /// - Parameters:
    ///   - progress: The fill level from 0.0 to 1.0.
    ///   - gradient: The gradient for the water. Defaults to the hydration gradient.
    ///   - waveHeight: The amplitude of the wave. Defaults to 10.
    init(
        progress: Double,
        gradient: LinearGradient = Color.hydrationGradient,
        waveHeight: Double = 10
    ) {
        self.progress = progress
        self.gradient = gradient
        self.waveHeight = waveHeight
    }

    var body: some View {
        ZStack {
            // Primary wave
            WaveShape(
                progress: progress,
                waveHeight: reduceMotion ? 0 : waveHeight,
                offset: waveOffset
            )
            .fill(gradient)
            .opacity(0.8)

            // Secondary wave for depth
            WaveShape(
                progress: progress,
                waveHeight: reduceMotion ? 0 : waveHeight * 0.7,
                offset: waveOffset + .pi / 3
            )
            .fill(gradient)
            .opacity(0.5)
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
        .onAppear {
            startWaveAnimation()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Water level")
        .accessibilityValue("\(Int(min(max(progress, 0), 1) * 100)) percent full")
    }

    /// Starts the continuous wave offset animation if motion is not reduced.
    private func startWaveAnimation() {
        guard !reduceMotion else { return }
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            waveOffset = 2.0 * .pi
        }
    }
}

/// A view that clips arbitrary content to a wave-shaped mask, creating a water-fill clipping effect.
///
/// Use this to clip images, patterns, or other content to the wave shape.
struct WaterFillClip<Content: View>: View {
    /// The fill level from 0.0 (empty) to 1.0 (full).
    var progress: Double

    /// The amplitude of the wave oscillation.
    var waveHeight: Double

    /// The content to clip with the wave shape.
    @ViewBuilder var content: () -> Content

    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The continuously incrementing wave phase offset.
    @State private var waveOffset: Double = 0.0

    /// Creates a new water fill clip view.
    /// - Parameters:
    ///   - progress: The fill level from 0.0 to 1.0.
    ///   - waveHeight: The amplitude of the wave. Defaults to 10.
    ///   - content: The content to clip with the wave shape.
    init(
        progress: Double,
        waveHeight: Double = 10,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.progress = progress
        self.waveHeight = waveHeight
        self.content = content
    }

    var body: some View {
        content()
            .clipShape(
                WaveShape(
                    progress: progress,
                    waveHeight: reduceMotion ? 0 : waveHeight,
                    offset: waveOffset
                )
            )
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    waveOffset = 2.0 * .pi
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Water level")
            .accessibilityValue("\(Int(min(max(progress, 0), 1) * 100)) percent full")
    }
}

#Preview("Wave Shape — 60% Fill") {
    ZStack {
        Color.deepNavy.ignoresSafeArea()

        VStack(spacing: 32) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.deepNavy.opacity(0.3))
                .frame(width: 200, height: 300)
                .overlay(
                    WaterFillView(progress: 0.6)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                )
                .overlay(
                    Text("60%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                )

            HStack(spacing: 16) {
                ForEach([0.25, 0.5, 0.75], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.deepNavy.opacity(0.3))
                        .frame(width: 80, height: 120)
                        .overlay(
                            WaterFillView(progress: level)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        )
                        .overlay(
                            Text("\(Int(level * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        )
                }
            }
        }
    }
}
