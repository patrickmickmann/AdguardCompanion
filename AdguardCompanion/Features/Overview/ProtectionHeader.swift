import SwiftUI

/// Hero at the top of the Overview: one glance answers "Is my network protected?"
struct ProtectionHeader: View {
    let summary: ProtectionSummary
    let version: String?
    let isDemo: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 64

    var body: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: summary.systemImage)
                .font(.system(size: symbolSize, weight: .regular))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, summary.tone.color.gradient)
                .contentTransition(.symbolEffect(.replace))
                .shadow(color: summary.tone.color.opacity(0.3), radius: 12, y: 4)
                .padding(.bottom, Spacing.xs)
                .accessibilityHidden(true)

            Text(summary.title)
                .font(.title2.bold())
            Text(summary.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if isDemo {
                DemoBadge()
                    .padding(.top, Spacing.xs)
            } else if let version {
                Text("AdGuard Home \(version)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.m)
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
