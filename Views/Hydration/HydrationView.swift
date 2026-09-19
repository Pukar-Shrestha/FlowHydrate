import SwiftUI
import SwiftData

/// The main hydration tracking screen displaying water-fill visualization,
/// quick-add buttons, and today's water intake log.
struct HydrationView: View {
    /// The hydration view model provided through the environment.
    @Environment(HydrationViewModel.self) private var viewModel

    /// The SwiftData model context for persistence operations.
    @Environment(\.modelContext) private var modelContext

    /// System preference for reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Controls the visibility of the custom amount input sheet.
    @State private var showingCustomAmount: Bool = false

    /// The text value entered in the custom amount sheet.
    @State private var customAmountText: String = ""

    /// Columns for the quick add buttons grid.
    private let quickAddColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    waterFillCard
                    quickAddSection
                    todaysLogSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hydration")
            .onAppear {
                viewModel.loadTodayData(modelContext: modelContext)
            }
            .sheet(isPresented: $showingCustomAmount) {
                customAmountSheet
            }
        }
    }

    // MARK: - Water Fill Card

    /// Prominent card containing the animated water-fill visualization.
    private var waterFillCard: some View {
        VStack(spacing: 16) {
            WaterFillView(
                progress: viewModel.progress,
                currentIntake: viewModel.currentIntake,
                dailyGoal: viewModel.dailyGoal,
                glassesConsumed: viewModel.glassesConsumed,
                volumeUnit: .milliliters,
                size: 260
            )
            .padding(.top, 8)

            // Remaining intake label
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(Color.aqua)
                Text("\(viewModel.remainingIntake) mL remaining")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondary)
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.aqua.opacity(0.1), radius: 16, x: 0, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.aqua.opacity(0.15), lineWidth: 1)
        }
    }

    // MARK: - Quick Add Section

    /// Section with grid of preset water amount buttons and custom input.
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.primary)

            LazyVGrid(columns: quickAddColumns, spacing: 12) {
                ForEach(HydrationViewModel.quickAmounts, id: \.self) { amount in
                    QuickAddButton(amount: amount, unit: .milliliters) {
                        withAnimation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.7)) {
                            viewModel.addWater(amount: amount, modelContext: modelContext)
                        }
                    }
                }
            }

            // Custom amount button
            Button {
                customAmountText = ""
                showingCustomAmount = true
            } label: {
                Label("Custom Amount", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.aqua)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.aqua.opacity(0.3), lineWidth: 1)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    }
            }
            .accessibilityLabel("Add custom amount of water")
            .accessibilityHint("Opens a sheet to enter a custom water amount")
        }
    }

    // MARK: - Today's Log Section

    /// Section showing today's logged water entries with swipe-to-delete.
    private var todaysLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Log")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.primary)

                Spacer()

                Text("\(viewModel.todayLogs.count) entries")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

            if viewModel.todayLogs.isEmpty {
                emptyLogState
            } else {
                logEntries
            }
        }
    }

    /// Individual log entries with swipe-to-delete functionality.
    private var logEntries: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.todayLogs) { log in
                logRow(for: log)
            }
        }
    }

    /// A single log entry row displaying timestamp and amount.
    private func logRow(for log: WaterLog) -> some View {
        HStack {
            // Water drop icon
            Circle()
                .fill(Color.hydrationGradient)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(Color.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(log.amount) mL")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            // Delete button
            Button(role: .destructive) {
                withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.removeLog(log, modelContext: modelContext)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(Color.red.opacity(0.7))
                    .padding(8)
                    .background(Color.red.opacity(0.1), in: Circle())
            }
            .accessibilityLabel("Delete \(log.amount) milliliter entry")
            .accessibilityHint("Removes this water log from today's records")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.amount) milliliters at \(log.timestamp.formatted(date: .omitted, time: .shortened))")
    }

    /// Empty state displayed when no water has been logged today.
    private var emptyLogState: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.secondary.opacity(0.4))
                .symbolEffect(.pulse, options: .repeating)

            Text("No water logged today")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.secondary)

            Text("Use the quick add buttons above to get started")
                .font(.caption)
                .foregroundStyle(Color.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("No water logged today. Use the quick add buttons to start tracking.")
    }

    // MARK: - Custom Amount Sheet

    /// Sheet for entering a custom water amount.
    private var customAmountSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header illustration
                Image(systemName: "drop.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.hydrationGradient)
                    .padding(.top, 20)

                Text("Enter Amount")
                    .font(.title2.weight(.bold))

                // Amount input
                VStack(spacing: 8) {
                    TextField("Amount in mL", text: $customAmountText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("Custom water amount in milliliters")
                        .accessibilityHint("Enter the amount of water you drank")

                    Text("milliliters")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }

                // Add button
                GradientButton(
                    title: "Add Water",
                    icon: "plus.circle.fill",
                    gradient: Color.hydrationGradient
                ) {
                    addCustomAmount()
                }
                .disabled(parsedCustomAmount == nil)
                .opacity(parsedCustomAmount == nil ? 0.5 : 1.0)

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCustomAmount = false
                    }
                    .accessibilityLabel("Cancel custom amount entry")
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    /// Parses the custom amount text into a valid integer, or nil if invalid.
    private var parsedCustomAmount: Int? {
        guard let value = Int(customAmountText), value > 0, value <= 5000 else {
            return nil
        }
        return value
    }

    /// Validates and adds the custom water amount, then dismisses the sheet.
    private func addCustomAmount() {
        guard let amount = parsedCustomAmount else { return }
        withAnimation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.7)) {
            viewModel.addWater(amount: amount, modelContext: modelContext)
        }
        showingCustomAmount = false
    }
}

// MARK: - Preview

#Preview {
    HydrationView()
        .environment(HydrationViewModel())
        .modelContainer(for: WaterLog.self, inMemory: true)
}
