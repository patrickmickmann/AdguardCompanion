import SwiftUI

/// Typography tokens. All styles are text-style based to support Dynamic Type.
enum AppFont {
    /// Hero figure of a card, e.g. the number of queries (Health style).
    static let heroValue = Font.system(.largeTitle, design: .rounded).weight(.semibold).monospacedDigit()
    /// Secondary figures in insight cards.
    static let value = Font.system(.title, design: .rounded).weight(.semibold).monospacedDigit()
    /// Unit next to a value ("Anfragen", "ms").
    static let unit = Font.system(.subheadline, design: .rounded).weight(.semibold)
    /// Card header label next to its symbol.
    static let cardLabel = Font.subheadline.weight(.semibold)
    /// Technical identifiers such as IP addresses, URLs and versions.
    static let technical = Font.system(.subheadline, design: .monospaced)
    /// Compact technical identifiers.
    static let technicalSmall = Font.system(.footnote, design: .monospaced)
}
