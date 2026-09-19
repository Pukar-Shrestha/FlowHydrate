import SwiftUI
import SwiftData

/// Statistics screen presenting charts and summary cards for focus sessions
/// and hydration data across daily, weekly, and monthly time periods.
struct StatisticsView: View {
    /// The statistics view model managed locally since it's only used here.
    @State private var viewModel = StatisticsViewModel()

    /// The SwiftData model context for querying historical data.
    @Environment(\.modelContext) private var modelContext

    /// System preference for reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Columns for the summary cards grid.
    private let summaryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker
                    summaryCardsSection
                    focusChartSection
                    hydrationChartSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
            .onAppear {
                viewModel.loadData(modelContext: modelContext)
            }
            .onChange(of: viewModel.selectedPeriod) { _, _ in
                withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
                    viewModel.loadData(modelContext: modelContext)
                }
            }
        }
    }

    // MARK: - Period Picker

    /// Segmented picker for selecting the statistics time period.
    private var periodPicker: some View {
        @Bindable var vm = viewModel
        return Picker("Time Period", selection: $vm.selectedPeriod) {
            ForEach(StatisticsViewModel.Period.allCases) { period in
                Text(period.displayName)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Statistics time period")
        .accessibilityHint("Choose between daily, weekly, and monthly views")
    }

    // MARK: - Summary Cards

    /// Grid of summary statistic cards.
    private var summaryCardsSection: some View {
        LazyVGrid(columns: summaryColumns, spacing: 12) {
            summaryCard(
                title: "Focus Time",
                value: "\(viewModel.totalFocusMinutes)",
                unit: "min",
                icon: "brain.head.profile.fill",
                color: .electricBlue
            )

            summaryCard(
                title: "Sessions",
                value: "\(viewModel.totalSessions)",
                unit: "completed",
                icon: "checkmark.circle.fill",
                color: .mintGreen
            )

            summaryCard(
                title: "Avg. Water",
                value: "\(viewModel.averageIntake)",
                unit: "mL/day",
                icon: "drop.fill",
                color: .aqua
            )

            summaryCard(
                title: "Goal Rate",
                value: "\(viewModel.goalCompletionRate)",
                unit: "%",
                icon: "target",
                color: .mintGreen
            )
        }
    }

    /// A single summary statistic card.
    private func summaryCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Spacer()
            }

            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.primary)
                .contentTransition(.numericText())

            HStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)

                if !unit.isEmpty {
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary.opacity(0.5))
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(Color.secondary.opacity(0.7))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }

    // MARK: - Charts

    /// Focus time chart section with animated transitions.
    private var focusChartSection: some View {
        FocusChartView(
            data: viewModel.focusData,
            period: viewModel.selectedPeriod
        )
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: viewModel.selectedPeriod)
    }

    /// Hydration intake chart section with animated transitions.
    private var hydrationChartSection: some View {
        HydrationChartView(
            data: viewModel.hydrationData,
            dailyGoal: 2500,
            period: viewModel.selectedPeriod,
            volumeUnit: .milliliters
        )
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: viewModel.selectedPeriod)
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .modelContainer(for: WaterLog.self, inMemory: true)
}
