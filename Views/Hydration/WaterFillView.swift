import SwiftUI

/// Animated water-fill visualization that renders a circular glass filling with
/// dual animated wave layers. Overlays current hydration statistics including
/// percentage, intake amounts, and glasses consumed.
struct WaterFillView: View {
    /// Current hydration progress from 0.0 to 1.0.
    let progress: Double

    /// Current water intake in milliliters.
    let currentIntake: Int

    /// Daily hydration goal in milliliters.
    let dailyGoal: Int

    /// Number of glasses consumed today.
    let glassesConsumed: Int

    /// The volume unit for display formatting.
    let volumeUnit: VolumeUnit

    /// Diameter of the circular container in points.
    var size: CGFloat = 250

    /// Continuously animated wave horizontal offset.
    @State private var waveOffset: Double = 0

    /// Whether the wave animation timer is active.
    @State private var isAnimating: Bool = false

    /// System preference for reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Display-ready percentage value clamped to 0–100.
    private var percentageValue: Int {
        Int(min(max(progress, 0), 1) * 100)
    }

    /// Clamped progress value for rendering.
    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            // MARK: - Background Circle
            Circle()
                .fill(Color.deepNavy.opacity(0.1))
                .frame(width: size, height: size)

            // MARK: - Wave Layers
            if clampedProgress > 0 {
                // Primary wave layer
                WaveShape(
                    progress: clampedProgress,
                    waveHeight: reduceMotion ? 0 : 8,
                    offset: waveOffset
                )
                .fill(Color.hydrationGradient)
                .frame(width: size, height: size)

                // Secondary wave layer for depth effect
                WaveShape(
                    progress: clampedProgress,
                    waveHeight: reduceMotion ? 0 : 6,
                    offset: waveOffset + .pi / 3
                )
                .fill(Color.hydrationGradient.opacity(0.5))
                .frame(width: size, height: size)
            }

            // MARK: - Stats Overlay
            statsOverlay
        }
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color.aqua.opacity(0.3), lineWidth: 2)
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.aqua.opacity(0.2), radius: 12, x: 0, y: 6)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            isAnimating = false
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hydration progress")
        .accessibilityValue("\(percentageValue) percent, \(volumeUnit.displayAmount(currentIntake)) of \(volumeUnit.displayAmount(dailyGoal)) \(volumeUnit.symbol)")
    }

    // MARK: - Stats Overlay

    /// Overlay displaying percentage, intake, and glass count.
    private var statsOverlay: some View {
        VStack(spacing: 6) {
            // Percentage
            Text("\(percentageValue)%")
                .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                .foregroundStyle(clampedProgress > 0.45 ? Color.white : Color.primary)
                .contentTransition(.numericText())

            // Current / Goal
            Text("\(volumeUnit.formatted(currentIntake)) / \(volumeUnit.formatted(dailyGoal))")
                .font(.system(size: size * 0.055, weight: .medium, design: .rounded))
                .foregroundStyle(clampedProgress > 0.45 ? Color.white.opacity(0.9) : Color.secondary)

            // Glasses count
            HStack(spacing: 4) {
                Image(systemName: "waterbottle.fill")
                    .font(.system(size: size * 0.05))
                Text("\(glassesConsumed) glasses")
                    .font(.system(size: size * 0.048, weight: .medium, design: .rounded))
            }
            .foregroundStyle(clampedProgress > 0.45 ? Color.white.opacity(0.85) : Color.secondary)
            .padding(.top, 2)
        }
    }

    // MARK: - Animation

    /// Starts the continuous wave animation using a timer, respecting Reduce Motion.
    private func startAnimation() {
        guard !reduceMotion else { return }
        isAnimating = true
        withAnimation(
            .linear(duration: 2.5)
            .repeatForever(autoreverses: false)
        ) {
            waveOffset = .pi * 2
        }
    }
}

// MARK: - Preview

#Preview("Half Full") {
    WaterFillView(
        progress: 0.5,
        currentIntake: 1250,
        dailyGoal: 2500,
        glassesConsumed: 5,
        volumeUnit: .milliliters
    )
    .padding()
}

#Preview("Nearly Complete") {
    WaterFillView(
        progress: 0.85,
        currentIntake: 2125,
        dailyGoal: 2500,
        glassesConsumed: 8,
        volumeUnit: .milliliters,
        size: 300
    )
    .padding()
}

#Preview("Empty") {
    WaterFillView(
        progress: 0.0,
        currentIntake: 0,
        dailyGoal: 2500,
        glassesConsumed: 0,
        volumeUnit: .ounces
    )
    .padding()
}
