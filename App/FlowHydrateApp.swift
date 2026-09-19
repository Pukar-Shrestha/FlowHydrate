import SwiftUI
import SwiftData

/// The main entry point for the FlowHydrate wellness app.
///
/// Configures the SwiftData model container, injects shared view models
/// into the environment, handles scene-phase transitions for the focus timer,
/// and requests notification authorization on first launch.
@main
struct FlowHydrateApp: App {
    /// Shared SwiftData model container for persistence.
    let modelContainer: ModelContainer

    /// Global focus-timer view model shared across the app.
    @State private var focusTimerVM = FocusTimerViewModel()

    /// Global hydration view model shared across the app.
    @State private var hydrationVM = HydrationViewModel()

    /// Global settings view model shared across the app.
    @State private var settingsVM = SettingsViewModel()

    /// Global streak view model shared across the app.
    @State private var streakVM = StreakViewModel()

    /// Tracks the current scene phase for background / foreground transitions.
    @Environment(\.scenePhase) private var scenePhase

    init() {
        modelContainer = PersistenceService.sharedModelContainer
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(focusTimerVM)
                .environment(hydrationVM)
                .environment(settingsVM)
                .environment(streakVM)
                .preferredColorScheme(settingsVM.preferredColorScheme)
                .onChange(of: scenePhase) { _, newPhase in
                    focusTimerVM.handleScenePhase(newPhase)
                }
                .task {
                    await requestNotificationAuthorization()
                }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Private Helpers

    /// Requests notification authorization from the user on first launch.
    private func requestNotificationAuthorization() async {
        await NotificationService.shared.requestAuthorization()
    }
}
