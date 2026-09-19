import AudioToolbox

/// Plays system sounds for key app events like timer completion and water logging.
///
/// Uses `AudioServicesPlaySystemSound` for lightweight, no-latency playback
/// without requiring AVAudioSession configuration.
final class SoundService: Sendable {
    /// Shared singleton instance
    static let shared = SoundService()

    /// System sound ID for a pleasant completion chime
    private let completionSoundID: SystemSoundID = 1025

    /// System sound ID for a water drop effect
    private let waterDropSoundID: SystemSoundID = 1104

    private init() {}

    /// Plays a completion chime, suitable for timer end events.
    func playCompletion() {
        AudioServicesPlaySystemSound(completionSoundID)
    }

    /// Plays a water drop sound, suitable for hydration log events.
    func playWaterDrop() {
        AudioServicesPlaySystemSound(waterDropSoundID)
    }
}
