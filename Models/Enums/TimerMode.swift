import SwiftUI

/// Represents the three phases of a Pomodoro-style focus timer cycle.
enum TimerMode: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Deep work period
    case focus

    /// Short rest between focus sessions
    case shortBreak

    /// Extended rest after a series of focus sessions
    case longBreak

    /// Stable identity for SwiftUI lists and navigation
    var id: String { rawValue }

    /// Human-readable name for display in the UI
    var displayName: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        }
    }

    /// Default duration in seconds for this mode
    var defaultDuration: TimeInterval {
        switch self {
        case .focus: 1500      // 25 minutes
        case .shortBreak: 300  // 5 minutes
        case .longBreak: 900   // 15 minutes
        }
    }

    /// Brand color associated with this mode
    var color: Color {
        switch self {
        case .focus: .electricBlue
        case .shortBreak: .mintGreen
        case .longBreak: .aqua
        }
    }

    /// SF Symbol icon representing this mode
    var icon: String {
        switch self {
        case .focus: "brain.head.profile"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "leaf.fill"
        }
    }

    /// Mode-specific gradient used for backgrounds and progress rings
    var gradient: LinearGradient {
        switch self {
        case .focus:
            LinearGradient(
                colors: [.electricBlue, .aqua],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .shortBreak:
            LinearGradient(
                colors: [.mintGreen, .aqua],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .longBreak:
            LinearGradient(
                colors: [.aqua, .mintGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
