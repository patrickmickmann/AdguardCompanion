import SwiftUI
import UIKit

/// Semantic color tokens. Dark-first palette derived from the reference mockup,
/// with tuned light-mode counterparts for sufficient contrast.
enum AppColor {
    /// Screen background behind grouped content.
    static let background = adaptive(light: 0xF2F4F3, dark: 0x0A0C0B)
    /// Primary surface for cards and grouped rows.
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x161917)
    /// Raised surface inside cards (e.g. metric tiles).
    static let surfaceRaised = adaptive(light: 0xF6F8F7, dark: 0x1E2220)
    /// Hairline outline for surfaces.
    static let outline = adaptive(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.07, darkAlpha: 0.08)

    /// Active protection, positive states and primary actions.
    static let protection = Color.accentColor
    /// Blocked requests and critical states.
    static let blocked = adaptive(light: 0xD7372E, dark: 0xFF5A50)
    /// Warnings and degraded states.
    static let warning = adaptive(light: 0xA86A00, dark: 0xFFB020)
    /// Neutral, inactive or unknown states.
    static let neutral = Color.secondary

    /// Foreground for content placed on the protection color.
    static let onProtection = adaptive(light: 0xFFFFFF, dark: 0x06140A)

    private static func adaptive(
        light: UInt32,
        dark: UInt32,
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
