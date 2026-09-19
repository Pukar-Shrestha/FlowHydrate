import SwiftUI
import SwiftData

/// The root tab-based navigation view for FlowHydrate.
///
/// Provides four primary tabs — Dashboard, Focus, Hydration, and Statistics —
/// each with its own navigation stack. Data is loaded on appear for tabs
/// that require it.
struct MainTabView: View {
    /// The currently selected tab.
    @State private var selectedTab: Tab = .dashboard

    /// The focus timer view model from the environment.
    @Environment(FocusTimerViewModel.self) private var focusTimerVM

    /// The hydration view model from the environment.
    @Environment(HydrationViewModel.self) private var hydrationVM

    /// The settings view model from the environment.
    @Environment(SettingsViewModel.self) private var settingsVM

    /// The streak view model from the environment.
    @Environment(StreakViewModel.self) private var streakVM

    /// SwiftData model context for data operations.
    @Environment(\.modelContext) private var modelContext

    /// Represents each navigable tab in the app.
    enum Tab: String, CaseIterable, Sendable {
        case dashboard
        case focus
        case hydration
        case statistics

        /// The user-visible display name for the tab.
        var displayName: String {
            switch self {
            case .dashboard: "Dashboard"
            case .focus: "Focus"
            case .hydration: "Hydration"
            case .statistics: "Statistics"
            }
        }

        /// The SF Symbol name for the tab icon.
        var icon: String {
            switch self {
            case .dashboard: "house.fill"
            case .focus: "timer"
            case .hydration: "drop.fill"
            case .statistics: "chart.bar.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.displayName, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(.electricBlue)
        .accessibilityLabel("Main navigation")
    }

    // MARK: - Tab Content

    /// Returns the appropriate view for the given tab.
    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .focus:
            FocusTimerView()
        case .hydration:
            HydrationView()
        case .statistics:
            StatisticsView()
        }
    }
}

// MARK: - Placeholder Views

/// Placeholder view for the Hydration tab.
///
/// Will be replaced with the full hydration tracking interface.
struct HydrationView: View {
    @Environment(HydrationViewModel.self) private var hydrationVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Text("Hydration Tracker")
                .font(.largeTitle)
                .navigationTitle("Hydration")
        }
        .onAppear {
            hydrationVM.loadTodayData(modelContext: modelContext)
        }
    }
}

/// Placeholder view for the Statistics tab.
///
/// Will be replaced with the full statistics and charts interface.
struct StatisticsView: View {
    var body: some View {
        NavigationStack {
            Text("Statistics & Insights")
                .font(.largeTitle)
                .navigationTitle("Statistics")
        }
    }
}

#Preview {
    MainTabView()
        .environment(FocusTimerViewModel())
        .environment(HydrationViewModel())
        .environment(SettingsViewModel())
        .environment(StreakViewModel())
        .modelContainer(PersistenceService.sharedModelContainer)
}
