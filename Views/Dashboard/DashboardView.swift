import SwiftUI
import SwiftData

/// The main dashboard home screen for FlowHydrate.
///
/// Displays a greeting, today's date, focus and hydration summary cards,
/// a streak badge, and quick-action buttons. Cards animate in with a
/// staggered spring animation on appear.
struct DashboardView: View {
    /// Dashboard-specific data aggregation view model.
    @State private var dashboardVM = DashboardViewModel()

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

    /// Controls whether the settings sheet is presented.
    @State private var showSettings = false

    /// Tracks whether the initial card entrance animation has played.
    @State private var hasAppeared = false

    /// Whether the user has Reduce Motion enabled.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Today's date formatted for display.
    private var formattedDate: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    focusSummarySection
                    hydrationSummarySection
                    streakSection
                    quickActionsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("FlowHydrate")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsButton
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                dashboardVM.loadData(modelContext: modelContext)
                hydrationVM.loadTodayData(modelContext: modelContext)
                withAnimation(reduceMotion ? .none : .easeIn(duration: 0.3)) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Header

    /// Greeting text and today's date subtitle.
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dashboardVM.greeting)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Text(formattedDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 10)
        .animation(
            reduceMotion ? .none : .spring(duration: 0.5),
            value: hasAppeared
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dashboardVM.greeting). \(formattedDate)")
    }

    // MARK: - Focus Summary

    /// Card showing today's focus progress with staggered animation.
    private var focusSummarySection: some View {
        FocusSummaryCard(
            focusMinutes: dashboardVM.todayFocusMinutes,
            sessionsCompleted: dashboardVM.todayFocusSessions
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(
            reduceMotion ? .none : .spring(duration: 0.5).delay(0.1),
            value: hasAppeared
        )
    }

    // MARK: - Hydration Summary

    /// Card showing today's hydration progress with staggered animation.
    private var hydrationSummarySection: some View {
        HydrationSummaryCard(
            currentIntake: dashboardVM.todayWaterIntake,
            dailyGoal: dashboardVM.waterGoal
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(
            reduceMotion ? .none : .spring(duration: 0.5).delay(0.2),
            value: hasAppeared
        )
    }

    // MARK: - Streak

    /// Streak badge with staggered animation.
    private var streakSection: some View {
        StreakBadge()
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(
                reduceMotion ? .none : .spring(duration: 0.5).delay(0.3),
                value: hasAppeared
            )
    }

    // MARK: - Quick Actions

    /// Row of quick-action buttons for starting focus or adding water.
    private var quickActionsSection: some View {
        HStack(spacing: 16) {
            GradientButton(
                title: "Start Focus",
                icon: "brain.head.profile",
                gradient: .focusGradient
            ) {
                HapticService.shared.light()
                focusTimerVM.start(
                    settings: settingsVM,
                    modelContext: modelContext
                )
            }
            .accessibilityHint("Starts a new focus timer session")

            GradientButton(
                title: "Add Water",
                icon: "plus.circle.fill",
                gradient: .hydrationGradient
            ) {
                HapticService.shared.light()
                hydrationVM.addWater(
                    amount: hydrationVM.quickAmounts.first ?? 250,
                    modelContext: modelContext
                )
            }
            .accessibilityHint("Logs a glass of water to today's intake")
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(
            reduceMotion ? .none : .spring(duration: 0.5).delay(0.4),
            value: hasAppeared
        )
    }

    // MARK: - Toolbar

    /// Settings gear button in the navigation toolbar.
    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens the app settings")
    }
}

// MARK: - Placeholder Settings View

/// Placeholder settings view presented as a sheet from the dashboard.
///
/// Will be replaced with the full settings interface.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Settings")
                .font(.largeTitle)
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .accessibilityLabel("Done")
                        .accessibilityHint("Closes the settings screen")
                    }
                }
        }
    }
}

#Preview {
    DashboardView()
        .environment(FocusTimerViewModel())
        .environment(HydrationViewModel())
        .environment(SettingsViewModel())
        .environment(StreakViewModel())
        .modelContainer(PersistenceService.sharedModelContainer)
}
