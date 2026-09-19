import Foundation
import SwiftData

/// Configures and provides the shared SwiftData `ModelContainer` for the app.
///
/// All four model types — `FocusSession`, `WaterLog`, `DailyRecord`, and
/// `UserSettings` — are registered in a single container backed by persistent
/// on-disk storage.
enum PersistenceService {
    /// The shared model container used throughout the app.
    ///
    /// Initialized once on first access. If container creation fails, the app
    /// cannot function and a `fatalError` is raised as a last resort.
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FocusSession.self,
            WaterLog.self,
            DailyRecord.self,
            UserSettings.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError(
                "Failed to create ModelContainer: \(error.localizedDescription)"
            )
        }
    }()
}
