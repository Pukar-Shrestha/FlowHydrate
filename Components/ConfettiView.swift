import SwiftUI

/// A lightweight confetti particle animation for milestone celebrations.
///
/// Renders ~50 colorful particles that fall from the top of the screen with
/// random horizontal drift, rotation, and varying speeds. The animation
/// lasts approximately 3 seconds before auto-dismissing. When the system
/// requests reduced motion, a simple opacity pulse is shown instead.
struct ConfettiView: View {
    /// Controls whether the confetti animation is active.
    @Binding var isActive: Bool

    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The collection of confetti particles.
    @State private var particles: [ConfettiParticle] = []

    /// Whether the particle animation is currently in its animated state.
    @State private var isAnimating = false

    /// Controls the reduced-motion pulse opacity.
    @State private var pulseOpacity: Double = 0.0

    /// The number of confetti particles to generate.
    private let particleCount = 50

    /// The duration of the confetti animation in seconds.
    private let animationDuration: Double = 3.0

    var body: some View {
        if isActive {
            ZStack {
                if reduceMotion {
                    reducedMotionView
                } else {
                    particleCanvasView
                }
            }
            .allowsHitTesting(false)
            .onAppear {
                startAnimation()
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startAnimation()
                }
            }
            .accessibilityHidden(true)
        }
    }

    /// The Canvas-based particle animation view.
    private var particleCanvasView: some View {
        Canvas { context, size in
            for particle in particles {
                let currentX = isAnimating
                    ? particle.endX * size.width
                    : particle.startX * size.width
                let currentY = isAnimating
                    ? size.height + 20
                    : -20
                let currentRotation = isAnimating
                    ? particle.endRotation
                    : particle.startRotation

                context.opacity = isAnimating ? 0.0 : 1.0

                var transformedContext = context
                transformedContext.translateBy(x: currentX, y: currentY)
                transformedContext.rotate(by: .degrees(currentRotation))

                let rect = CGRect(
                    x: -particle.size / 2,
                    y: -particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )

                if particle.isCircle {
                    transformedContext.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color)
                    )
                } else {
                    transformedContext.fill(
                        Path(rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .animation(
            .easeIn(duration: animationDuration),
            value: isAnimating
        )
    }

    /// A simple opacity pulse shown when Reduce Motion is enabled.
    private var reducedMotionView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: ConfettiParticle.availableColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 200, height: 60)
            .overlay(
                Text("🎉")
                    .font(.largeTitle)
            )
            .opacity(pulseOpacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                    pulseOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    pulseOpacity = 0.0
                    isActive = false
                }
            }
    }

    /// Starts the confetti animation by generating particles and triggering their fall.
    private func startAnimation() {
        isAnimating = false
        particles = (0..<particleCount).map { _ in
            ConfettiParticle.random()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isAnimating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) {
            isActive = false
            isAnimating = false
            particles = []
        }
    }
}

/// A single confetti particle with randomized visual properties.
struct ConfettiParticle: Identifiable {
    /// The unique identifier for this particle.
    let id = UUID()

    /// The normalized horizontal start position (0.0–1.0).
    let startX: Double

    /// The normalized horizontal end position (0.0–1.0), simulating drift.
    let endX: Double

    /// The starting rotation in degrees.
    let startRotation: Double

    /// The ending rotation in degrees.
    let endRotation: Double

    /// The diameter or side length of the particle.
    let size: Double

    /// The color of the particle.
    let color: Color

    /// Whether the particle is rendered as a circle (true) or rectangle (false).
    let isCircle: Bool

    /// The available confetti colors.
    static let availableColors: [Color] = [
        .electricBlue, .aqua, .mintGreen, .yellow, .orange, .pink
    ]

    /// Creates a randomized confetti particle.
    /// - Returns: A new ``ConfettiParticle`` with random properties.
    static func random() -> ConfettiParticle {
        let startX = Double.random(in: 0.05...0.95)
        let drift = Double.random(in: -0.15...0.15)

        return ConfettiParticle(
            startX: startX,
            endX: min(max(startX + drift, 0.0), 1.0),
            startRotation: Double.random(in: 0...360),
            endRotation: Double.random(in: 360...1080),
            size: Double.random(in: 4...10),
            color: availableColors.randomElement() ?? .electricBlue,
            isCircle: Bool.random()
        )
    }
}

#Preview("Confetti View") {
    struct ConfettiPreview: View {
        @State private var showConfetti = false

        var body: some View {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("🎉 Milestone Reached!")
                        .font(.title2.bold())

                    Button("Celebrate!") {
                        showConfetti = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                ConfettiView(isActive: $showConfetti)
            }
        }
    }
    return ConfettiPreview()
}
