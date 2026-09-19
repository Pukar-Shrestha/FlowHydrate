import Foundation

/// Supported volume measurement units for hydration tracking.
enum VolumeUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Metric milliliters
    case milliliters

    /// Imperial fluid ounces
    case ounces

    /// Stable identity for SwiftUI pickers
    var id: String { rawValue }

    /// Abbreviated unit symbol for compact display
    var symbol: String {
        switch self {
        case .milliliters: "mL"
        case .ounces: "oz"
        }
    }

    /// Conversion factor from milliliters to fluid ounces
    private static let mlToOzFactor: Double = 0.033814

    /// Converts a value stored in milliliters to the display unit.
    /// - Parameter ml: The amount in milliliters.
    /// - Returns: The equivalent amount in this unit.
    func displayAmount(_ ml: Double) -> Double {
        switch self {
        case .milliliters: ml
        case .ounces: ml * Self.mlToOzFactor
        }
    }

    /// Converts a value in this display unit back to milliliters for storage.
    /// - Parameter value: The amount in the current display unit.
    /// - Returns: The equivalent amount in milliliters.
    func toML(_ value: Double) -> Double {
        switch self {
        case .milliliters: value
        case .ounces: value / Self.mlToOzFactor
        }
    }

    /// Formats a milliliter amount as a human-readable string in this unit.
    ///
    /// - Parameter ml: The amount in milliliters.
    /// - Returns: A formatted string such as "250 mL" or "8.5 oz".
    func formatted(_ ml: Double) -> String {
        let displayValue = displayAmount(ml)
        switch self {
        case .milliliters:
            return "\(Int(displayValue)) \(symbol)"
        case .ounces:
            let rounded = (displayValue * 10).rounded() / 10
            if rounded == rounded.rounded() {
                return "\(Int(rounded)) \(symbol)"
            }
            return String(format: "%.1f %@", rounded, symbol)
        }
    }
}
