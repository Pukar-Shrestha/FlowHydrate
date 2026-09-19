import SwiftUI

// MARK: - Color Palette

extension Color {
    /// Deep navy background color used for dark surfaces
    static let deepNavy = Color(red: 0.05, green: 0.05, blue: 0.2)

    /// Vibrant electric blue used as the primary accent color
    static let electricBlue = Color(red: 0.0, green: 0.48, blue: 1.0)

    /// Bright aqua color bridging focus and hydration themes
    static let aqua = Color(red: 0.0, green: 0.8, blue: 0.8)

    /// Fresh mint green representing hydration and wellness
    static let mintGreen = Color(red: 0.4, green: 0.95, blue: 0.7)

    /// Neutral dark gray for secondary surfaces and separators
    static let darkGray = Color(red: 0.15, green: 0.15, blue: 0.15)
}

// MARK: - Gradients

extension Color {
    /// Gradient used for focus timer UI elements (electric blue → aqua)
    static var focusGradient: LinearGradient {
        LinearGradient(
            colors: [.electricBlue, .aqua],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Gradient used for hydration tracker UI elements (aqua → mint green)
    static var hydrationGradient: LinearGradient {
        LinearGradient(
            colors: [.aqua, .mintGreen],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// General accent gradient spanning the full brand spectrum (electric blue → mint green)
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [.electricBlue, .mintGreen],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
