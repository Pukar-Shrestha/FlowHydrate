import SwiftUI
import SwiftData

/// Settings screen presented as a modal sheet, providing user-configurable
/// options for focus timer, hydration, appearance, health integrations,
/// and notifications in a grouped Form layout.
struct SettingsView: View {
    /// The settings view model provided through the environment.
    @Environment(SettingsViewModel.self) private var viewModel

    /// The SwiftData model context for persisting settings changes.
    @Environment(\.modelContext) private var modelContext

    /// The dismiss action for closing the sheet.
    @Environment(\.dismiss) private var dismiss

    /// Available reminder interval options in minutes.
    private let reminderIntervals: [Int] = [30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            settingsForm
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title3)
                                .foregroundStyle(Color.secondary)
                        }
                        .accessibilityLabel("Close settings")
                        .accessibilityHint("Dismisses the settings screen")
                    }
                }
                .onAppear {
                    viewModel.loadSettings(modelContext: modelContext)
                }
        }
    }

    // MARK: - Form

    /// The main settings form with grouped sections.
    private var settingsForm: some View {
        @Bindable var vm = viewModel
        return Form {
            focusTimerSection(vm: vm)
            hydrationSection(vm: vm)
            appearanceSection(vm: vm)
            healthSection(vm: vm)
            notificationsSection(vm: vm)
            aboutSection
        }
    }

    // MARK: - Focus Timer Section

    /// Settings for configuring focus timer durations and behavior.
    @ViewBuilder
    private func focusTimerSection(vm: Bindable<SettingsViewModel>) -> some View {
        Section {
            // Focus Duration (stored in seconds, displayed in minutes)
            Stepper(
                "Focus Duration: \(vm.wrappedValue.focusDuration / 60) min",
                value: Binding(
                    get: { vm.wrappedValue.focusDuration / 60 },
                    set: { newValue in
                        vm.wrappedValue.focusDuration = newValue * 60
                        saveSettings()
                    }
                ),
                in: 5...120,
                step: 5
            )
            .accessibilityLabel("Focus duration")
            .accessibilityValue("\(vm.wrappedValue.focusDuration / 60) minutes")
            .accessibilityHint("Adjusts focus session length from 5 to 120 minutes in 5 minute steps")

            // Short Break Duration
            Stepper(
                "Short Break: \(vm.wrappedValue.shortBreakDuration / 60) min",
                value: Binding(
                    get: { vm.wrappedValue.shortBreakDuration / 60 },
                    set: { newValue in
                        vm.wrappedValue.shortBreakDuration = newValue * 60
                        saveSettings()
                    }
                ),
                in: 1...30,
                step: 1
            )
            .accessibilityLabel("Short break duration")
            .accessibilityValue("\(vm.wrappedValue.shortBreakDuration / 60) minutes")
            .accessibilityHint("Adjusts short break length from 1 to 30 minutes")

            // Long Break Duration
            Stepper(
                "Long Break: \(vm.wrappedValue.longBreakDuration / 60) min",
                value: Binding(
                    get: { vm.wrappedValue.longBreakDuration / 60 },
                    set: { newValue in
                        vm.wrappedValue.longBreakDuration = newValue * 60
                        saveSettings()
                    }
                ),
                in: 5...60,
                step: 5
            )
            .accessibilityLabel("Long break duration")
            .accessibilityValue("\(vm.wrappedValue.longBreakDuration / 60) minutes")
            .accessibilityHint("Adjusts long break length from 5 to 60 minutes in 5 minute steps")

            // Auto-start next session
            Toggle("Auto-Start Next", isOn: Binding(
                get: { vm.wrappedValue.autoStartNext },
                set: { newValue in
                    vm.wrappedValue.autoStartNext = newValue
                    saveSettings()
                }
            ))
            .accessibilityLabel("Auto-start next session")
            .accessibilityHint("When enabled, the next timer phase starts automatically")
        } header: {
            Label("Focus Timer", systemImage: "timer")
                .foregroundStyle(Color.electricBlue)
        }
    }

    // MARK: - Hydration Section

    /// Settings for configuring hydration goals, reminders, and units.
    @ViewBuilder
    private func hydrationSection(vm: Bindable<SettingsViewModel>) -> some View {
        Section {
            // Daily Goal
            Stepper(
                "Daily Goal: \(vm.wrappedValue.dailyWaterGoal) mL",
                value: Binding(
                    get: { vm.wrappedValue.dailyWaterGoal },
                    set: { newValue in
                        vm.wrappedValue.dailyWaterGoal = newValue
                        saveSettings()
                    }
                ),
                in: 500...10000,
                step: 250
            )
            .accessibilityLabel("Daily water goal")
            .accessibilityValue("\(vm.wrappedValue.dailyWaterGoal) milliliters")
            .accessibilityHint("Adjusts daily hydration goal from 500 to 10000 milliliters in 250 milliliter steps")

            // Reminder Interval
            Picker("Reminder Interval", selection: Binding(
                get: { vm.wrappedValue.reminderInterval },
                set: { newValue in
                    vm.wrappedValue.reminderInterval = newValue
                    saveSettings()
                }
            )) {
                ForEach(reminderIntervals, id: \.self) { interval in
                    Text("\(interval) min")
                        .tag(interval)
                }
            }
            .accessibilityLabel("Hydration reminder interval")
            .accessibilityValue("\(vm.wrappedValue.reminderInterval) minutes")
            .accessibilityHint("Choose how often to be reminded to drink water")

            // Volume Units
            Picker("Units", selection: Binding(
                get: { vm.wrappedValue.volumeUnit },
                set: { newValue in
                    vm.wrappedValue.volumeUnit = newValue
                    saveSettings()
                }
            )) {
                ForEach(VolumeUnit.allCases, id: \.self) { unit in
                    Text(unit.symbol)
                        .tag(unit)
                }
            }
            .accessibilityLabel("Volume unit")
            .accessibilityValue(vm.wrappedValue.volumeUnit.symbol)
            .accessibilityHint("Choose between milliliters and fluid ounces")
        } header: {
            Label("Hydration", systemImage: "drop.fill")
                .foregroundStyle(Color.aqua)
        }
    }

    // MARK: - Appearance Section

    /// Settings for configuring app appearance mode.
    @ViewBuilder
    private func appearanceSection(vm: Bindable<SettingsViewModel>) -> some View {
        Section {
            Picker("Appearance", selection: Binding(
                get: { vm.wrappedValue.appearanceMode },
                set: { newValue in
                    vm.wrappedValue.appearanceMode = newValue
                    saveSettings()
                }
            )) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.displayName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Appearance mode")
            .accessibilityValue(vm.wrappedValue.appearanceMode.displayName)
            .accessibilityHint("Choose between system, light, and dark appearance")
        } header: {
            Label("Appearance", systemImage: "paintbrush.fill")
                .foregroundStyle(Color.mintGreen)
        }
    }

    // MARK: - Health Section

    /// Settings for HealthKit integration, only shown when HealthKit is available.
    @ViewBuilder
    private func healthSection(vm: Bindable<SettingsViewModel>) -> some View {
        if HealthKitService.shared.isAvailable {
            Section {
                Toggle("Sync with Health", isOn: Binding(
                    get: { vm.wrappedValue.healthKitSync },
                    set: { newValue in
                        vm.wrappedValue.healthKitSync = newValue
                        saveSettings()
                        if newValue {
                            Task {
                                await HealthKitService.shared.requestAuthorization()
                            }
                        }
                    }
                ))
                .accessibilityLabel("HealthKit sync")
                .accessibilityHint("When enabled, water intake data is shared with Apple Health")
            } header: {
                Label("Health", systemImage: "heart.fill")
                    .foregroundStyle(Color.red)
            }
        }
    }

    // MARK: - Notifications Section

    /// Settings for enabling or disabling push notifications.
    @ViewBuilder
    private func notificationsSection(vm: Bindable<SettingsViewModel>) -> some View {
        Section {
            Toggle("Enable Notifications", isOn: Binding(
                get: { vm.wrappedValue.notificationsEnabled },
                set: { newValue in
                    vm.wrappedValue.notificationsEnabled = newValue
                    saveSettings()
                }
            ))
            .accessibilityLabel("Notifications")
            .accessibilityHint("When enabled, you will receive reminders for hydration and focus sessions")
        } header: {
            Label("Notifications", systemImage: "bell.fill")
                .foregroundStyle(Color.orange)
        }
    }

    // MARK: - About Section

    /// Static information about the app.
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(Color.primary)
                Spacer()
                Text(appVersion)
                    .foregroundStyle(Color.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("App version \(appVersion)")

            HStack {
                Spacer()
                Text("Made with ❤️ for your wellness")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                Spacer()
            }
            .listRowBackground(Color.clear)
            .accessibilityLabel("Made with love for your wellness")
        } header: {
            Label("About", systemImage: "info.circle.fill")
                .foregroundStyle(Color.secondary)
        }
    }

    // MARK: - Helpers

    /// The current app version string from the main bundle.
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Persists the current view model state to SwiftData.
    private func saveSettings() {
        viewModel.save(modelContext: modelContext)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(SettingsViewModel())
        .modelContainer(for: UserSettings.self, inMemory: true)
}
