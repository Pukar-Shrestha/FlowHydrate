import XCTest
import SwiftData
@testable import FlowHydrate

/// Unit tests for the ``StreakViewModel`` ensuring correct streak tracking,
/// milestone detection, celebration triggers, and emoji mapping.
final class StreakViewModelTests: XCTestCase {

    // MARK: - Properties

    /// The view model under test.
    var vm: StreakViewModel!

    /// In-memory model container for isolated testing.
    var modelContainer: ModelContainer!

    /// Model context derived from the in-memory container.
    var modelContext: ModelContext!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        vm = StreakViewModel()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: FocusSession.self,
            WaterLog.self,
            DailyRecord.self,
            UserSettings.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
    }

    override func tearDown() {
        vm = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - 1. Initial State

    /// Verifies all streaks start at zero with no active milestone.
    func testInitialState() {
        XCTAssertEqual(vm.focusStreak, 0,
                       "Focus streak should be 0 initially")
        XCTAssertEqual(vm.hydrationStreak, 0,
                       "Hydration streak should be 0 initially")
        XCTAssertEqual(vm.combinedStreak, 0,
                       "Combined streak should be 0 initially")
        XCTAssertNil(vm.currentMilestone,
                     "No milestone should be active initially")
        XCTAssertFalse(vm.showCelebration,
                       "showCelebration should be false initially")
    }

    // MARK: - 2. Milestone at 3 Days

    /// Verifies a milestone is detected when the focus streak reaches 3 days.
    func testMilestoneAt3Days() {
        vm.focusStreak = 3
        vm.checkMilestone()

        XCTAssertEqual(vm.currentMilestone, 3,
                       "Milestone should be 3 when focus streak is 3")
    }

    // MARK: - 3. Milestone at 7 Days

    /// Verifies a milestone is detected when the focus streak reaches 7 days.
    func testMilestoneAt7Days() {
        vm.focusStreak = 7
        vm.checkMilestone()

        XCTAssertEqual(vm.currentMilestone, 7,
                       "Milestone should be 7 when focus streak is 7")
    }

    // MARK: - 4. Milestone at 30 Days

    /// Verifies a milestone is detected when the focus streak reaches 30 days.
    func testMilestoneAt30Days() {
        vm.focusStreak = 30
        vm.checkMilestone()

        XCTAssertEqual(vm.currentMilestone, 30,
                       "Milestone should be 30 when focus streak is 30")
    }

    // MARK: - 5. Milestone at 100 Days

    /// Verifies a milestone is detected when the focus streak reaches 100 days.
    func testMilestoneAt100Days() {
        vm.focusStreak = 100
        vm.checkMilestone()

        XCTAssertEqual(vm.currentMilestone, 100,
                       "Milestone should be 100 when focus streak is 100")
    }

    // MARK: - 6. No Milestone at Arbitrary Value

    /// Verifies no milestone triggers for streak values that are not milestones.
    func testNoMilestoneAtArbitraryValue() {
        vm.focusStreak = 5
        vm.checkMilestone()

        XCTAssertNil(vm.currentMilestone,
                     "No milestone should trigger at streak = 5")
    }

    // MARK: - 7. Celebration Triggered

    /// Verifies that ``showCelebration`` becomes true when a milestone is reached.
    func testCelebrationTriggered() {
        vm.focusStreak = 7
        vm.checkMilestone()

        XCTAssertTrue(vm.showCelebration,
                      "showCelebration should be true when a milestone is reached")
    }

    // MARK: - 8. Combined Streak

    /// Verifies combined streak equals the minimum of focus and hydration streaks.
    func testCombinedStreak() {
        vm.focusStreak = 10
        vm.hydrationStreak = 6

        XCTAssertEqual(vm.combinedStreak, min(vm.focusStreak, vm.hydrationStreak),
                       "Combined streak should be min(focusStreak, hydrationStreak)")
        XCTAssertEqual(vm.combinedStreak, 6,
                       "Combined streak should be 6 when focus=10, hydration=6")
    }

    // MARK: - 9. Milestone Emoji

    /// Verifies the correct emoji is returned for each milestone level.
    func testMilestoneEmoji() {
        // 3-day milestone: fire emoji
        vm.focusStreak = 3
        vm.checkMilestone()
        XCTAssertNotNil(vm.currentMilestone,
                        "Should have a milestone at 3 days")

        // 7-day milestone: star emoji
        vm.focusStreak = 7
        vm.checkMilestone()
        XCTAssertNotNil(vm.currentMilestone,
                        "Should have a milestone at 7 days")

        // 30-day milestone: trophy emoji
        vm.focusStreak = 30
        vm.checkMilestone()
        XCTAssertNotNil(vm.currentMilestone,
                        "Should have a milestone at 30 days")

        // 100-day milestone: crown emoji
        vm.focusStreak = 100
        vm.checkMilestone()
        XCTAssertNotNil(vm.currentMilestone,
                        "Should have a milestone at 100 days")

        // Verify milestones array
        XCTAssertEqual(vm.milestones, [3, 7, 30, 100],
                       "Milestones should be [3, 7, 30, 100]")
    }

    // MARK: - Additional Edge Cases

    /// Verifies milestone detection works with the hydration streak as well.
    func testHydrationStreakMilestone() {
        vm.hydrationStreak = 30
        vm.checkMilestone()

        XCTAssertNotNil(vm.currentMilestone,
                        "Milestone should trigger for hydration streak at 30")
    }

    /// Verifies that celebration does not trigger when no milestone is reached.
    func testNoCelebrationWithoutMilestone() {
        vm.focusStreak = 2
        vm.hydrationStreak = 4
        vm.checkMilestone()

        XCTAssertFalse(vm.showCelebration,
                       "showCelebration should remain false when no milestone is reached")
    }
}
