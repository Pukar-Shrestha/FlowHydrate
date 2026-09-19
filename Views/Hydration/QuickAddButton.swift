import SwiftUI

/// A styled button for quickly adding a preset water amount.
/// Displays a water drop icon, the formatted amount in the current unit,
/// and provides haptic feedback on tap with a satisfying press animation.
struct QuickAddButton: View {
    /// The water amount in milliliters to add when tapped.
    let amount: Int

    /// The volume unit used for display formatting.
    let unit: VolumeUnit

    /// The action to perform when the button is tapped.
    let action: () -> Void

    /// Tracks whether the button is currently being pressed.
    @State private var isPressed: Bool = false

    /// System preference for reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Human-readable description of the amount with unit.
    private var formattedAmount: String {
        unit.formatted(amount)
    }

    var body: some View {
        Button {
            HapticService.shared.impact(.medium)
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(Color.aqua)
                    .symbolEffect(.bounce, value: isPressed)

                Text(formattedAmount)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text(unit.symbol)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.aqua.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Add \(formattedAmount) \(unit.symbol) of water")
        .accessibilityHint("Double-tap to log this amount to today's hydration")
    }
}

/// A button style that applies a subtle scale-down effect on press,
/// respecting the user's Reduce Motion preference.
struct ScaleButtonStyle: ButtonStyle {
    /// System preference for reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

// MARK: - Preview

#Preview("Quick Add Buttons Grid") {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 12) {
        QuickAddButton(amount: 100, unit: .milliliters) { }
        QuickAddButton(amount: 250, unit: .milliliters) { }
        QuickAddButton(amount: 500, unit: .milliliters) { }
        QuickAddButton(amount: 750, unit: .milliliters) { }
    }
    .padding()
}

#Preview("Ounces") {
    QuickAddButton(amount: 250, unit: .ounces) { }
        .frame(width: 160)
        .padding()
}
