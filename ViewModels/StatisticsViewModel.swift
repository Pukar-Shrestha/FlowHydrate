import Foundation
import SwiftUI
import SwiftData

// MARK: - Supporting Types

/// A time period used to bucket statistics for chart display.
enum StatisticsPeriod: String, CaseIterable, Identifiable {
    /// Last 24 hours, bucketed by hour.
    case daily
    /// Last 7 days, bucketed by day.
    case weekly
    /// Last 30 days, bucketed by day.
    case monthly

    /// Unique identifier for `Identifiable` conformance.
    var id: String { rawValue }

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

/// A single data point used to populate Swift Charts.
struct ChartDataPoint: Identifiable {
    /// Unique identifier.
    let id: UUID = UUID()
    /// The date (or bucket start) this data point represents.
    let date: Date
    /// The numeric value (minutes for focus, mL for hydration).
    let value: Double
    /// A short label suitable for the chart axis.
    let label: String
}

// MARK: - StatisticsViewModel

/// Computes and exposes aggregated focus and hydration data for Swift Charts
/// across daily, weekly, and monthly periods.
@Observable
final class StatisticsViewModel {

    // MARK: - State

    /// The currently selected time period.
    var selectedPeriod: StatisticsPeriod = .weekly

    /// Focus data points for the selected period (value = minutes).
    var focusData: [ChartDataPoint] = []

    /// Hydration data points for the selected period (value = mL).
    var hydrationData: [ChartDataPoint] = []

    /// Total focus minutes within the selected period.
    var totalFocusMinutes: Double = 0

    /// Total completed focus sessions within the selected period.
    var totalSessions: Int = 0

    /// Average daily water intake (mL) within the selected period.
    var averageIntake: Double = 0

    /// Percentage of days where the hydration goal was met.
    var goalCompletionRate: Double = 0

    /// Longest combined streak found in daily records.
    var longestStreak: Int = 0

    // MARK: - Formatted Strings

    /// Total focus formatted as hours and minutes.
    var formattedTotalFocus: String {
        let hours = Int(totalFocusMinutes) / 60
        let minutes = Int(totalFocusMinutes) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Average water intake formatted in litres.
    var formattedAverageIntake: String {
        String(format: "%.1f L", averageIntake / 1000)
    }

    /// Goal completion rate as a percentage string.
    var formattedGoalRate: String {
        "\(Int((goalCompletionRate * 100).rounded()))%"
    }

    // MARK: - Data Loading

    /// Fetches and aggregates data for the selected period.
    ///
    /// - Parameter modelContext: SwiftData model context for querying.
    func loadData(modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        let (startDate, bucketComponent, bucketCount): (Date, Calendar.Component, Int) = {
            switch selectedPeriod {
            case .daily:
                let start = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
                return (start, .hour, 24)
            case .weekly:
                let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                return (start, .day, 7)
            case .monthly:
                let start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
                return (start, .day, 30)
            }
        }()

        loadFocusData(modelContext: modelContext, startDate: startDate, bucketComponent: bucketComponent, bucketCount: bucketCount, calendar: calendar, now: now)
        loadHydrationData(modelContext: modelContext, startDate: startDate, bucketComponent: bucketComponent, bucketCount: bucketCount, calendar: calendar, now: now)
        loadStreakData(modelContext: modelContext)
        loadGoalCompletion(modelContext: modelContext, startDate: startDate)
    }

    // MARK: - Private Aggregation

    /// Fetches focus sessions within the range and buckets them.
    private func loadFocusData(modelContext: ModelContext, startDate: Date, bucketComponent: Calendar.Component, bucketCount: Int, calendar: Calendar, now: Date) {

        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { session in
                session.completed && session.startDate >= startDate
            },
            sortBy: [SortDescriptor(\.startDate)]
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            totalSessions = sessions.count
            totalFocusMinutes = sessions.reduce(0) { $0 + $1.duration } / 60.0

            focusData = buildBuckets(startDate: startDate, component: bucketComponent, count: bucketCount, calendar: calendar, now: now) { bucketStart, bucketEnd in
                let bucketSessions = sessions.filter { $0.startDate >= bucketStart && $0.startDate < bucketEnd }
                return bucketSessions.reduce(0) { $0 + $1.duration } / 60.0
            }
        } catch {
            focusData = []
            totalFocusMinutes = 0
            totalSessions = 0
        }
    }

    /// Fetches water logs within the range and buckets them.
    private func loadHydrationData(modelContext: ModelContext, startDate: Date, bucketComponent: Calendar.Component, bucketCount: Int, calendar: Calendar, now: Date) {

        let descriptor = FetchDescriptor<WaterLog>(
            predicate: #Predicate<WaterLog> { log in
                log.timestamp >= startDate
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )

        do {
            let logs = try modelContext.fetch(descriptor)
            let totalIntake = logs.reduce(0) { $0 + $1.amount }
            let days = max(1, selectedPeriod == .daily ? 1 : (selectedPeriod == .weekly ? 7 : 30))
            averageIntake = totalIntake / Double(days)

            hydrationData = buildBuckets(startDate: startDate, component: bucketComponent, count: bucketCount, calendar: calendar, now: now) { bucketStart, bucketEnd in
                let bucketLogs = logs.filter { $0.timestamp >= bucketStart && $0.timestamp < bucketEnd }
                return bucketLogs.reduce(0) { $0 + $1.amount }
            }
        } catch {
            hydrationData = []
            averageIntake = 0
        }
    }

    /// Loads the longest streak from daily records.
    private func loadStreakData(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let records = try modelContext.fetch(descriptor)
            longestStreak = records.map(\.combinedStreak).max() ?? 0
        } catch {
            longestStreak = 0
        }
    }

    /// Calculates the percentage of days within the period where the hydration goal was met.
    private func loadGoalCompletion(modelContext: ModelContext, startDate: Date) {
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { record in
                record.date >= startDate
            }
        )

        do {
            let records = try modelContext.fetch(descriptor)
            guard !records.isEmpty else {
                goalCompletionRate = 0
                return
            }
            let metCount = records.filter(\.hydrationGoalMet).count
            goalCompletionRate = Double(metCount) / Double(records.count)
        } catch {
            goalCompletionRate = 0
        }
    }

    /// Builds evenly-spaced time buckets and fills them using the provided aggregation closure.
    ///
    /// - Parameters:
    ///   - startDate: The beginning of the range.
    ///   - component: Calendar component for each bucket (`.hour` or `.day`).
    ///   - count: Number of buckets.
    ///   - calendar: Calendar instance.
    ///   - now: Current date.
    ///   - aggregate: Closure returning the aggregated value for a bucket range.
    /// - Returns: An array of `ChartDataPoint` values.
    private func buildBuckets(startDate: Date, component: Calendar.Component, count: Int, calendar: Calendar, now: Date, aggregate: (Date, Date) -> Double) -> [ChartDataPoint] {
        var points: [ChartDataPoint] = []
        let dateFormatter = DateFormatter()

        switch component {
        case .hour:
            dateFormatter.dateFormat = "HH:mm"
        default:
            dateFormatter.dateFormat = "MMM d"
        }

        for i in 0..<count {
            guard let bucketStart = calendar.date(byAdding: component, value: i, to: startDate) else { continue }
            let bucketEnd = calendar.date(byAdding: component, value: 1, to: bucketStart) ?? now
            let value = aggregate(bucketStart, bucketEnd)
            let label = dateFormatter.string(from: bucketStart)
            points.append(ChartDataPoint(date: bucketStart, value: value, label: label))
        }

        return points
    }
}
