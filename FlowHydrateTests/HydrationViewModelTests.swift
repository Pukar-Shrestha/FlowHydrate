import XCTest
import SwiftData
@testable import FlowHydrate

/// Unit tests for the ``HydrationViewModel`` ensuring correct water tracking,
/// progress computation, and boundary handling.
final class HydrationViewModelTests: XCTestCase {

    // MARK: - Properties

    /// The view model under test.
    var vm: HydrationViewModel!

    /// In-memory model container for isolated testing.
    var modelContainer: ModelContainer!

    /// Model context derived from the in-memory container.
    var modelContext: ModelContext!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        vm = HydrationViewModel()
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

    /// Verifies the view model starts with zero intake and the default daily goal.
    func testInitialState() {
        XCTAssertEqual(vm.currentIntake, 0,
                       "Current intake should be 0 initially")
        XCTAssertEqual(vm.dailyGoal, 2500,
                       "Default daily goal should be 2500 mL")
        XCTAssertEqual(vm.progress, 0,
                       "Progress should be 0 initially")
    }

    // MARK: - 2. Add Water

    /// Verifies adding a single water entry updates current intake correctly.
    func testAddWater() {
        vm.addWater(amount: 250, modelContext: modelContext)

        XCTAssertEqual(vm.currentIntake, 250, accuracy: 0.01,
                       "Current intake should be 250 after adding 250 mL")
    }

    // MARK: - 3. Multiple Adds

    /// Verifies multiple water additions accumulate correctly.
    func testMultipleAdds() {
        vm.addWater(amount: 100, modelContext: modelContext)
        vm.addWater(amount: 250, modelContext: modelContext)
        vm.addWater(amount: 500, modelContext: modelContext)

        XCTAssertEqual(vm.currentIntake, 850, accuracy: 0.01,
                       "Current intake should be 850 after adding 100 + 250 + 500")
    }

    // MARK: - 4. Progress Calculation

    /// Verifies progress is correctly calculated as currentIntake / dailyGoal.
    func testProgressCalculation() {
        vm.addWater(amount: 1250, modelContext: modelContext)

        XCTAssertEqual(vm.progress, 0.5, accuracy: 0.01,
                       "Progress should be 0.5 when intake is half of goal (1250/2500)")
    }

    // MARK: - 5. Remaining Intake

    /// Verifies remaining intake equals dailyGoal minus currentIntake.
    func testRemainingIntake() {
        vm.addWater(amount: 1000, modelContext: modelContext)

        XCTAssertEqual(vm.remainingIntake, 1500, accuracy: 0.01,
                       "Remaining intake should be 1500 (2500 - 1000)")
    }

    // MARK: - 6. Glasses Consumed

    /// Verifies glasses consumed is calculated as currentIntake / 250 (standard glass size).
    func testGlassesConsumed() {
        vm.addWater(amount: 750, modelContext: modelContext)

        XCTAssertEqual(vm.glassesConsumed, 3,
                       "750 mL should equal 3 glasses (250 mL each)")
    }

    // MARK: - 7. Progress Caps At One

    /// Verifies progress never exceeds 1.0 even when intake surpasses the goal.
    func testProgressCapsAtOne() {
        vm.addWater(amount: 3000, modelContext: modelContext)

        XCTAssertEqual(vm.progress, 1.0, accuracy: 0.001,
                       "Progress should cap at 1.0 when intake exceeds daily goal")
    }

    // MARK: - 8. Remaining Never Negative

    /// Verifies remaining intake never drops below zero when intake exceeds goal.
    func testRemainingNeverNegative() {
        vm.addWater(amount: 3000, modelContext: modelContext)

        XCTAssertGreaterThanOrEqual(vm.remainingIntake, 0,
                                     "Remaining intake should never be negative")
    }

    // MARK: - 9. Quick Amounts

    /// Verifies the quick-add amounts constant contains the expected presets.
    func testQuickAmounts() {
        let expectedAmounts: [Double] = [100, 250, 500, 750]

        XCTAssertEqual(HydrationViewModel.quickAmounts, expectedAmounts,
                       "Quick amounts should be [100, 250, 500, 750]")
    }
}
