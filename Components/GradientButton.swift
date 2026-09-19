import SwiftUI

/// The available size options for a gradient button.
///
/// Controls padding, font size, and icon size to maintain
/// visual consistency across different button contexts.
enum ButtonSize: Sendable {
    /// A compact button suitable for inline or secondary actions.
    case small
    /// The default button size for primary actions.
    case regular
    /// A large, prominent button for hero actions.
    case large

    /// The vertical padding for this button size.
    var verticalPadding: CGFloat {
        switch self {
        case .small: 8
        case .regular: 14
        case .large: 18
        }
    }

    /// The horizontal padding for this button size.
    var horizontalPadding: CGFloat {
        switch self {
        case .small: 16
        case .regular: 24
        case .large: 32
        }
    }

    /// The font appropriate for this button size.
    var font: Font {
        switch self {
        case .small: .subheadline.weight(.semibold)
        case .regular: .body.weight(.semibold)
        case .large: .title3.weight(.semibold)
        }
    }

    /// The icon font appropriate for this button size.
    var iconFont: Font {
        switch self {
        case .small: .subheadline
        case .regular: .body
        case .large: .title3
        }
    }

    /// The corner radius for this button size.
    var cornerRadius: CGFloat {
        switch self {
        case .small: 10
        case .regular: 16
        case .large: 20
        }
    }
}

/// A primary action button with a gradient fill, icon, and haptic feedback.
///
/// Displays a SF Symbol icon alongside a text title over a gradient background.
/// Supports three sizes, optional full-width layout, and provides tactile
/// feedback on press via haptic impact.
struct GradientButton: View {
    /// The button's text label.
    var title: String

    /// The SF Symbol name for the button's icon.
    var icon: String

    /// The gradient applied to the button background.
    var gradient: LinearGradient

    /// Whether the button should expand to fill the available width.
    var isFullWidth: Bool

    /// The size variant of the button.
    var size: ButtonSize

    /// The action to perform when the button is tapped.
    var action: () -> Void

    /// Creates a new gradient button.
    /// - Parameters:
    ///   - title: The text label for the button.
    ///   - icon: The SF Symbol name for the icon.
    ///   - gradient: The gradient for the background. Defaults to the accent gradient.
    ///   - isFullWidth: Whether the button expands to fill width. Defaults to false.
    ///   - size: The size variant. Defaults to `.regular`.
    ///   - action: The closure to execute on tap.
    init(
        title: String,
        icon: String,
        gradient: LinearGradient = Color.accentGradient,
        isFullWidth: Bool = false,
        size: ButtonSize = .regular,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.isFullWidth = isFullWidth
        self.size = size
        self.action = action
    }

    var body: some View {
        Button {
            HapticService.shared.impact(.light)
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(size.iconFont)

                Text(title)
                    .font(size.font)
            }
            .foregroundStyle(.white)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(gradient)
            )
        }
        .buttonStyle(GradientButtonPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

/// A button style that provides a subtle scale-down press effect.
///
/// On press, the button scales to 0.96 of its normal size with a
/// spring animation, providing tactile visual feedback. Respects
/// Reduce Motion by using a simpler animation.
struct GradientButtonPressStyle: ButtonStyle {
    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(
                reduceMotion
                    ? .linear(duration: 0.1)
                    : .spring(response: 0.3, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

/// A reusable button style that applies gradient background styling.
///
/// Use this directly with SwiftUI's `.buttonStyle()` modifier for custom
/// gradient button appearances without the full ``GradientButton`` wrapper.
struct GradientButtonStyle: ButtonStyle {
    /// The gradient applied to the button background.
    var gradient: LinearGradient

    /// The size variant controlling padding and corner radius.
    var size: ButtonSize

    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Creates a new gradient button style.
    /// - Parameters:
    ///   - gradient: The gradient for the background. Defaults to the accent gradient.
    ///   - size: The size variant. Defaults to `.regular`.
    init(
        gradient: LinearGradient = Color.accentGradient,
        size: ButtonSize = .regular
    ) {
        self.gradient = gradient
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundStyle(.white)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(gradient)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(
                reduceMotion
                    ? .linear(duration: 0.1)
                    : .spring(response: 0.3, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

/// A lightweight haptic feedback service.
///
/// Provides a shared instance for triggering UIKit haptic impacts
/// throughout the app. Centralizes haptic generation to allow
/// easy customization or disabling in the future.
final class HapticService: Sendable {
    /// The shared singleton instance.
    static let shared = HapticService()

    /// Private initializer to enforce singleton usage.
    private init() {}

    /// Triggers an impact haptic feedback.
    /// - Parameter style: The intensity style of the impact.
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Triggers a notification haptic feedback.
    /// - Parameter type: The type of notification feedback.
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    /// Triggers a selection changed haptic feedback.
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

#Preview("Gradient Buttons — All Sizes") {
    VStack(spacing: 20) {
        GradientButton(
            title: "Start Focus",
            icon: "play.fill",
            size: .small
        ) { }

        GradientButton(
            title: "Start Focus",
            icon: "play.fill"
        ) { }

        GradientButton(
            title: "Start Focus",
            icon: "play.fill",
            size: .large
        ) { }

        GradientButton(
            title: "Log Water",
            icon: "drop.fill",
            gradient: Color.hydrationGradient,
            isFullWidth: true
        ) { }

        GradientButton(
            title: "Complete Session",
            icon: "checkmark.circle.fill",
            gradient: Color.focusGradient,
            isFullWidth: true,
            size: .large
        ) { }
    }
    .padding()
}

#Preview("GradientButtonStyle — Custom Usage") {
    VStack(spacing: 16) {
        Button {
            // action
        } label: {
            Label("Custom Style", systemImage: "star.fill")
        }
        .buttonStyle(GradientButtonStyle())

        Button {
            // action
        } label: {
            Label("Hydration Style", systemImage: "drop.fill")
        }
        .buttonStyle(GradientButtonStyle(gradient: Color.hydrationGradient, size: .large))
    }
    .padding()
}
