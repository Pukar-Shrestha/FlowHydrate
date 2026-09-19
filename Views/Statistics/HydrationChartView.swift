import SwiftUI
import Charts

/// Swift Charts visualization for daily hydration intake.
/// Renders `BarMark` entries for each data point, a dashed `RuleMark`
/// showing the daily goal line, and interactive tap-to-select annotations.
struct HydrationChartView: View {
    /// The chart data points to render.
    let data: [ChartDataPoint]

    /// The daily hydration goal in milliliters, used for the rule mark.
    let dailyGoal: Int

    /// The currently selected time period.
    let period: StatisticsViewModel.Period

    /// The volume unit for formatting labels.
    let volumeUnit: VolumeUnit

    /// The currently selected data point for annotation display.
    @State private var selectedPoint: ChartDataPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hydration", systemImage: "drop.fill")
                .font(.headline)
                .foregroundStyle(Color.aqua)

            if data.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hydration chart")
    }

    // MARK: - Chart Content

    /// The chart rendering hydration bars and goal line.
    private var chartContent: some View {
        Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("Date", point.date, unit: dateUnit),
                    y: .value("Intake", point.value)
                )
                .foregroundStyle(Color.hydrationGradient)
                .cornerRadius(4)
                .opacity(selectedPoint?.id == point.id ? 1.0 : 0.85)
                .annotation(position: .top) {
                    if selectedPoint?.id == point.id {
                        annotationLabel(for: point)
                    }
                }
            }

            // Daily goal rule mark
            RuleMark(y: .value("Goal", dailyGoal))
                .foregroundStyle(Color.mintGreen.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Goal")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.mintGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.mintGreen.opacity(0.15))
                        )
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: dateStride)) { _ in
                AxisGridLine()
                AxisValueLabel(format: dateFormatStyle)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text(volumeUnit.formatted(intValue))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxisLabel(volumeUnit.symbol, position: .leading)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, proxy: proxy, geometry: geometry)
                    }
            }
        }
        .frame(height: 200)
        .accessibilityLabel("Hydration intake chart showing \(data.count) data points")
        .accessibilityValue(chartAccessibilityDescription)
    }

    // MARK: - Annotation

    /// A floating label showing the selected data point's value.
    private func annotationLabel(for point: ChartDataPoint) -> some View {
        Text(volumeUnit.formatted(Int(point.value)))
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.aqua, in: Capsule())
    }

    // MARK: - Empty State

    /// Placeholder displayed when no hydration data is available.
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.largeTitle)
                .foregroundStyle(Color.secondary.opacity(0.5))

            Text("No hydration data yet")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)

            Text("Start logging water to see your trends")
                .font(.caption)
                .foregroundStyle(Color.secondary.opacity(0.7))
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("No hydration data available")
    }

    // MARK: - Tap Handling

    /// Resolves a tap gesture location to the nearest data point.
    private func handleTap(at location: CGPoint, proxy: ChartProxy, geometry: GeometryReader<some View>.Content) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let tappedDate: Date = proxy.value(atX: xPosition) else {
            selectedPoint = nil
            return
        }

        // Find the closest data point to the tapped date
        let closest = data.min { pointA, pointB in
            abs(pointA.date.timeIntervalSince(tappedDate)) < abs(pointB.date.timeIntervalSince(tappedDate))
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedPoint?.id == closest?.id {
                selectedPoint = nil
            } else {
                selectedPoint = closest
            }
        }
    }

    // MARK: - Helpers

    /// The calendar unit for the x-axis based on period.
    private var dateUnit: Calendar.Component {
        switch period {
        case .daily: .hour
        case .weekly: .day
        case .monthly: .day
        }
    }

    /// The stride component for x-axis tick marks.
    private var dateStride: Calendar.Component {
        switch period {
        case .daily: .hour
        case .weekly: .day
        case .monthly: .weekOfYear
        }
    }

    /// The date format style for x-axis labels.
    private var dateFormatStyle: Date.FormatStyle {
        switch period {
        case .daily:
            .dateTime.hour()
        case .weekly:
            .dateTime.weekday(.abbreviated)
        case .monthly:
            .dateTime.day().month(.abbreviated)
        }
    }

    /// Accessibility summary of the chart data.
    private var chartAccessibilityDescription: String {
        guard let maxPoint = data.max(by: { $0.value < $1.value }),
              let minPoint = data.min(by: { $0.value < $1.value }) else {
            return "No data"
        }
        let total = data.reduce(0) { $0 + $1.value }
        let average = Int(total / Double(data.count))
        return "Ranges from \(volumeUnit.formatted(Int(minPoint.value))) to \(volumeUnit.formatted(Int(maxPoint.value))), averaging \(volumeUnit.formatted(average))"
    }
}

// MARK: - Preview

#Preview("Weekly Data") {
    let sampleData: [ChartDataPoint] = (0..<7).map { dayOffset in
        ChartDataPoint(
            date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now,
            value: Double.random(in: 800...3000),
            label: "Day \(dayOffset)"
        )
    }

    HydrationChartView(
        data: sampleData,
        dailyGoal: 2500,
        period: .weekly,
        volumeUnit: .milliliters
    )
    .padding()
}

#Preview("Empty State") {
    HydrationChartView(
        data: [],
        dailyGoal: 2500,
        period: .daily,
        volumeUnit: .milliliters
    )
    .padding()
}
