import Foundation
import SwiftUI
import SwiftData

// MARK: - StreakViewModel

/// Tracks and celebrates consecutive-day wellness streaks for focus, hydration,
/// and the combined metric.
@Observable
final class StreakViewModel {

    // MARK: - State

    /// Consecutive days the focus goal has been met.
    var focusStreak: Int = 0

    /// Consecutive days the hydration goal has been met.
    var hydrationStreak: Int = 0

    /// Consecutive days both goals have been met.
    var combinedStreak: Int = 0

    /// The milestone value currently being celebrated, or `nil` if none.
    var currentMilestone: Int?

    /// Whether the celebration overlay should be displayed.
    var showCelebration: Bool = false

    // MARK: - Constants

    /// Streak lengths that trigger a celebration.
    let milestones: [Int] = [3, 7, 30, 100]

    // MARK: - Computed Properties

    /// An emoji representing the highest milestone reached by the combined streak.
    var milestoneEmoji: String {
        guard let milestone = currentMilestone else {
            return streakEmoji(for: combinedStreak)
        }
        return emojiForMilestone(milestone)
    }

    /// A motivational message based on the current combined streak.
    var streakMessage: String {
        switch combinedStreak {
        case 0:
            return "Start your streak today!"
        case 1:
            return "Great start! Keep it going!"
        case 2:
            return "Two days strong!"
        case 3..<7:
            return "You're on fire! 🔥"
        case 7..<30:
            return "One week and counting! ⭐"
        case 30..<100:
            return "Incredible dedication! 🏆"
        default:
            return "Legendary streak! 💎"
        }
    }

    // MARK: - Data Loading

    /// Fetches recent `DailyRecord` entries and calculates consecutive-day streaks.
    ///
    /// The algorithm walks backwards from the most recent record, counting consecutive
    /// days where each goal was met.
    ///
    /// - Parameter modelContext: SwiftData model context for querying.
    func loadStreaks(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let records = try modelContext.fetch(descriptor)
            calculateStreaks(from: records)
        } catch {
            focusStreak = 0
            hydrationStreak = 0
            combinedStreak = 0
        }
    }

    // MARK: - Streak Update

    /// Updates the streaks for today's results and persists a `DailyRecord`.
    ///
    /// If a record for today already exists it is updated in place; otherwise a new
    /// record is created.
    ///
    /// - Parameters:
    ///   - focusGoalMet: Whether the focus goal was met today.
    ///   - hydrationGoalMet: Whether the hydration goal was met today.
    ///   - modelContext: SwiftData model context for persistence.
    func updateStreak(focusGoalMet: Bool, hydrationGoalMet: Bool, modelContext: ModelContext) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()

        // Check for an existing record for today.
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { record in
                record.date >= startOfToday && record.date < endOfToday
            }
        )

        do {
            let existing = try modelContext.fetch(descriptor)

            if let record = existing.first {
                // Update existing record.
                record.focusGoalMet = focusGoalMet
                record.hydrationGoalMet = hydrationGoalMet
                record.focusStreak = focusGoalMet ? focusStreak + 1 : 0
                record.hydrationStreak = hydrationGoalMet ? hydrationStreak + 1 : 0
                record.combinedStreak = (focusGoalMet && hydrationGoalMet) ? combinedStreak + 1 : 0
            } else {
                // Create a new record.
                let newFocusStreak = focusGoalMet ? focusStreak + 1 : 0
                let newHydrationStreak = hydrationGoalMet ? hydrationStreak + 1 : 0
                let newCombinedStreak = (focusGoalMet && hydrationGoalMet) ? combinedStreak + 1 : 0

                let record = DailyRecord(
                    id: UUID(),
                    date: startOfToday,
                    totalFocusMinutes: 0,
                    totalWaterIntake: 0,
                    focusSessionsCompleted: 0,
                    focusStreak: newFocusStreak,
                    hydrationStreak: newHydrationStreak,
                    combinedStreak: newCombinedStreak,
                    focusGoalMet: focusGoalMet,
                    hydrationGoalMet: hydrationGoalMet
                )
                modelContext.insert(record)
            }

            try? modelContext.save()

            // Reload streaks from the updated data.
            loadStreaks(modelContext: modelContext)

            // Check for milestone celebrations.
            checkMilestone()
        } catch {
            // Non-fatal; streaks will be recalculated on next load.
        }
    }

    // MARK: - Milestone Detection

    /// Checks whether the current combined streak matches a celebration milestone.
    func checkMilestone() {
        if milestones.contains(combinedStreak) {
            currentMilestone = combinedStreak
            showCelebration = true
            HapticService.shared.notification(.success)
        } else {
            currentMilestone = nil
            showCelebration = false
        }
    }

    /// Dismisses the celebration overlay.
    func dismissCelebration() {
        showCelebration = false
        currentMilestone = nil
    }

    // MARK: - Private Helpers

    /// Walks a reverse-sorted list of daily records to compute consecutive streaks.
    private func calculateStreaks(from records: [DailyRecord]) {
        var focus = 0
        var hydration = 0
        var combined = 0

        let calendar = Calendar.current
        var expectedDate = calendar.startOfDay(for: Date())

        for record in records {
            let recordDay = calendar.startOfDay(for: record.date)

            // Allow the current day to be missing (not yet recorded).
            if recordDay == expectedDate || recordDay == calendar.date(byAdding: .day, value: -1, to: expectedDate) {
                if recordDay != expectedDate {
                    // Shift expectation if today has no record yet.
                    expectedDate = recordDay
                }

                if record.focusGoalMet {
                    focus += 1
                } else {
                    // Stop counting focus streak once a gap is found.
                    if focus == 0 { focus = 0 }
                }

                if record.hydrationGoalMet {
                    hydration += 1
                } else {
                    if hydration == 0 { hydration = 0 }
                }

                if record.focusGoalMet && record.hydrationGoalMet {
                    combined += 1
                } else {
                    if combined == 0 { combined = 0 }
                }

                // Once all streaks are broken, stop scanning.
                let focusBroken = !record.focusGoalMet && focus > 0
                let hydrationBroken = !record.hydrationGoalMet && hydration > 0
                let combinedBroken = !(record.focusGoalMet && record.hydrationGoalMet) && combined > 0

                if focusBroken { focus = focus }
                if hydrationBroken { hydration = hydration }
                if combinedBroken { combined = combined }

                if focusBroken && hydrationBroken && combinedBroken {
                    break
                }

                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: expectedDate) else { break }
                expectedDate = previousDay
            } else {
                // Non-consecutive day — all streaks broken.
                break
            }
        }

        focusStreak = focus
        hydrationStreak = hydration
        combinedStreak = combined
    }

    /// Returns an emoji based on the streak length regardless of exact milestone.
    private func streakEmoji(for streak: Int) -> String {
        switch streak {
        case 100...:
            return "💎"
        case 30...:
            return "🏆"
        case 7...:
            return "⭐"
        case 3...:
            return "🔥"
        default:
            return "✨"
        }
    }

    /// Returns the celebration emoji for an exact milestone value.
    private func emojiForMilestone(_ milestone: Int) -> String {
        switch milestone {
        case 3: return "🔥"
        case 7: return "⭐"
        case 30: return "🏆"
        case 100: return "💎"
        default: return "🎉"
        }
    }
}
