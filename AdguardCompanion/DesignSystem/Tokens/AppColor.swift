import SwiftUI
import UIKit

/// Semantic color tokens built on system colors, so the app adapts to light/dark
/// mode, increased contrast and future OS styling exactly like Apple's own apps.
/// AdGuard green (the asset accent color) is the only brand color.
enum AppColor {
    /// Screen background behind grouped content.
    static let background = Color(uiColor: .systemGroupedBackground)
    /// Cards and grouped rows on top of `background`.
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    /// Subtle fill inside cards, e.g. tracks of bars and gauges.
    static let fill = Color(uiColor: .tertiarySystemFill)

    /// Active protection, positive states and primary actions.
    static let protection = Color.accentColor
    /// Blocked requests and critical states.
    static let blocked = Color(uiColor: .systemRed)
    /// Warnings and degraded states.
    static let warning = Color(uiColor: .systemOrange)
    /// Neutral, inactive or unknown states.
    static let neutral = Color.secondary
    /// Network and client related accents.
    static let network = Color(uiColor: .systemBlue)
    /// Performance related accents (response time).
    static let performance = Color(uiColor: .systemTeal)
}
