import SwiftUI

/// Semantic state used to color status indicators consistently.
enum StatusTone {
    case positive
    case warning
    case critical
    case neutral

    var color: Color {
        switch self {
        case .positive: AppColor.protection
        case .warning: AppColor.warning
        case .critical: AppColor.blocked
        case .neutral: AppColor.neutral
        }
    }
}

/// Small filled dot that communicates a state through color.
/// Always pair with a text label; color alone must not carry meaning.
struct StatusDot: View {
    let tone: StatusTone

    var body: some View {
        Circle()
            .fill(tone.color)
            .frame(width: Metrics.statusDot, height: Metrics.statusDot)
            .accessibilityHidden(true)
    }
}

/// Dot plus label, e.g. "Läuft" or "Nicht erreichbar".
struct StatusLabel: View {
    let text: String
    let tone: StatusTone

    var body: some View {
        HStack(spacing: Spacing.xs + Spacing.xxs) {
            StatusDot(tone: tone)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(tone.color)
        }
    }
}
