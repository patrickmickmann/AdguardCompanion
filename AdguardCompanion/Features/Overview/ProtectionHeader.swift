import SwiftUI

/// Compact status card at the top of the Overview: answers "Is my network
/// protected?" in one line, leaving the screen to the traffic data below.
struct ProtectionHeader: View {
    let summary: ProtectionSummary
    let version: String?
    let isDemo: Bool

    @ScaledMetric(relativeTo: .title) private var symbolSize: CGFloat = 40

    var body: some View {
        SurfaceCard(padding: Spacing.m) {
            HStack(spacing: Spacing.m) {
                Image(systemName: summary.systemImage)
                    .font(.system(size: symbolSize))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, summary.tone.color.gradient)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: symbolSize * 1.1)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(summary.title)
                        .font(.headline)
                    Text(summary.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if isDemo {
                        DemoBadge()
                            .padding(.top, Spacing.xs)
                    } else if let version {
                        Text("AdGuard Home \(version)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
        .animation(.smooth, value: summary)
    }
}

/// Marks sample data wherever it appears.
struct DemoBadge: View {
    var body: some View {
        Label("Demo · Beispieldaten", systemImage: "sparkles")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppColor.warning)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs + Spacing.xxs)
            .background(AppColor.warning.opacity(0.14), in: .capsule)
            .accessibilityLabel("Demo-Modus: Alle Werte sind Beispieldaten")
    }
}
