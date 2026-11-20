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

/// Corner radii used across surfaces (continuous corners).
enum Radius {
    static let card: CGFloat = 22
    static let small: CGFloat = 8
}

/// Fixed component dimensions. Text-related sizes use `@ScaledMetric` at the call site.
enum Metrics {
    static let statusDot: CGFloat = 8
    static let chartHeight: CGFloat = 200
    static let barCornerRadius: CGFloat = 3
    static let rankBarHeight: CGFloat = 5
    static let emptyStateHeight: CGFloat = 88
    static let readableWidth: CGFloat = 640
}
