import Foundation

nonisolated extension Duration {
    /// The duration in milliseconds as a floating-point value.
    var milliseconds: Double {
        Double(components.seconds) * 1000 + Double(components.attoseconds) / 1e15
    }

    var timeInterval: TimeInterval { milliseconds / 1000 }

    /// Whole milliseconds formatted for the current locale, e.g. "14".
    var formattedMilliseconds: String {
        milliseconds.formatted(.number.precision(.fractionLength(0)))
    }
}
