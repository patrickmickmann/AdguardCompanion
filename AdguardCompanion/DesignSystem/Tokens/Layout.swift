import CoreGraphics

/// Spacing scale on a 4 pt grid.
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// Corner radii used across surfaces.
enum Radius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 14
    static let large: CGFloat = 20
    static let button: CGFloat = 16
}

/// Fixed component dimensions that are not driven by Dynamic Type.
enum Metrics {
    static let statusDot: CGFloat = 10
    static let brandMarkLarge: CGFloat = 96
    static let featureIconWidth: CGFloat = 28
    static let chartHeight: CGFloat = 180
    static let rankBarHeight: CGFloat = 4
    static let outlineWidth: CGFloat = 1
}
