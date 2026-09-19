import Foundation
import SwiftData

/// A single water intake log entry persisted with SwiftData.
///
/// All amounts are stored internally in milliliters regardless of the user's
/// preferred display unit.
@Model
final class WaterLog {
    /// Unique identifier for this entry
    var id: UUID = UUID()

    /// Amount of water consumed, always stored in milliliters
    var amount: Double = 250.0

    /// When the water was consumed
    var timestamp: Date = Date()

    /// The intake expressed as number of standard glasses (250 mL each).
    @Transient
    var amountInGlasses: Double { amount / 250.0 }

    /// Creates a new water intake log entry.
    /// - Parameters:
    ///   - amount: Volume of water consumed in milliliters.
    ///   - timestamp: When the water was consumed. Defaults to now.
    init(amount: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = timestamp
    }
}
