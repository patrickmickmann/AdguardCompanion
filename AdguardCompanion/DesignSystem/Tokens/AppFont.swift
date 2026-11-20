import SwiftUI

/// Typography tokens. All styles are text-style based to support Dynamic Type.
enum AppFont {
    /// Large numeric values in metric tiles.
    static let metricValue = Font.title3.weight(.semibold).monospacedDigit()
    /// Small captions below metrics.
    static let metricLabel = Font.caption
    /// Card and section titles.
    static let cardTitle = Font.headline
    /// Technical identifiers such as IP addresses, URLs and versions.
    static let technical = Font.system(.subheadline, design: .monospaced)
    /// Compact technical identifiers.
    static let technicalSmall = Font.system(.caption, design: .monospaced)
}
