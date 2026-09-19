import UIKit

/// Centralized haptic feedback service for consistent tactile responses.
///
/// Wraps UIKit's feedback generators behind a simple API. The system
/// automatically respects the user's accessibility settings for haptics,
/// so no manual Reduce Motion check is required at the call site.
struct HapticService: Sendable {
    /// Shared singleton instance
    static let shared = HapticService()

    private init() {}

    /// Triggers an impact haptic with the specified style.
    /// - Parameter style: The intensity of the impact feedback. Defaults to `.medium`.
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Triggers a notification haptic for success, warning, or error events.
    /// - Parameter type: The type of notification feedback to play.
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    /// Triggers a subtle selection-change haptic, ideal for picker or toggle interactions.
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
