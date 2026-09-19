import SwiftUI

/// Controls the app's visual appearance theme.
enum AppearanceMode: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Follow the system-wide appearance setting
    case system

    /// Always use light mode
    case light

    /// Always use dark mode
    case dark

    /// Stable identity for SwiftUI lists and pickers
    var id: String { rawValue }

    /// Human-readable name for display in settings
    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// The corresponding `ColorScheme`, or `nil` when following the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
