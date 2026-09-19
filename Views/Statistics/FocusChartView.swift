import SwiftUI
import Charts

/// Swift Charts visualization for focus session data.
/// Uses `BarMark` for daily and weekly periods, and `LineMark` with
/// `AreaMark` for monthly aggregation. Includes empty state handling
/// and accessibility descriptions.
struct FocusChartView: View {
    /// The chart data points to render.
    let data: [ChartDataPoint]

    /// The currently selected time period, affects chart style.
    let period: StatisticsViewModel.Period

    /// System preference for reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Focus Time", systemImage: "brain.head.profile.fill")
                .font(.headline)
                .foregroundStyle(Color.electricBlue)

            if data.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Focus time chart")
    }

    // MARK: - Chart Content

    /// The chart view rendering focus data based on the selected period.
    @ViewBuilder
    private var chartContent: some View {
        Chart(data) { point in
            switch period {
            case .monthly:
                // Line + Area for monthly trend view
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Minutes", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.electricBlue.opacity(0.3), Color.electricBlue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Minutes", point.value)
                )
                .foregroundStyle(Color.electricBlue)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Minutes", point.value)
                )
                .foregroundStyle(Color.electricBlue)
                .symbolSize(30)

            case .daily, .weekly:
                // Bar chart for daily and weekly
                BarMark(
                    x: .value("Date", point.date, unit: dateUnit),
                    y: .value("Minutes", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.electricBlue, Color.electricBlue.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
        }
        .chartYAxisLabel("Minutes", position: .leading)
        .chartXAxis {
            AxisMarks(values: .stride(by: dateStride)) { value in
                AxisGridLine()
                AxisValueLabel(format: dateFormatStyle)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                AxisValueLabel()
            }
        }
        .frame(height: 200)
        .accessibilityLabel("Focus time chart showing \(data.count) data points")
        .accessibilityValue(chartAccessibilityDescription)
    }

    // MARK: - Empty State

    /// Placeholder displayed when no focus data is available.
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.largeTitle)
                .foregroundStyle(Color.secondary.opacity(0.5))

            Text("No focus data yet")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)

            Text("Complete focus sessions to see your stats")
                .font(.caption)
                .foregroundStyle(Color.secondary.opacity(0.7))
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("No focus data available")
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
        return "Ranges from \(Int(minPoint.value)) to \(Int(maxPoint.value)) minutes"
    }
}

// MARK: - Preview

#Preview("Weekly Data") {
    let sampleData: [ChartDataPoint] = (0..<7).map { dayOffset in
        ChartDataPoint(
            date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now,
            value: Double.random(in: 20...120),
            label: "Day \(dayOffset)"
        )
    }

    FocusChartView(data: sampleData, period: .weekly)
        .padding()
}

#Preview("Monthly Data") {
    let sampleData: [ChartDataPoint] = (0..<30).map { dayOffset in
        ChartDataPoint(
            date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now,
            value: Double.random(in: 10...90),
            label: "Day \(dayOffset)"
        )
    }

    FocusChartView(data: sampleData, period: .monthly)
        .padding()
}

#Preview("Empty State") {
    FocusChartView(data: [], period: .daily)
        .padding()
}
