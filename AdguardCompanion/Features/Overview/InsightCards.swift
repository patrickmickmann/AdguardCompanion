import SwiftUI

/// Two compact insight cards side by side; stacked at accessibility text sizes.
struct InsightCards: View {
    let statistics: DashboardStatistics

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.m))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.m))
        layout {
            BlockRateCard(statistics: statistics)
            ResponseTimeCard(averageResponseTime: statistics.averageResponseTime)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct BlockRateCard: View {
    let statistics: DashboardStatistics

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                CardHeader("Blockiert", systemImage: "hand.raised.fill", tint: AppColor.blocked)
                HStack(alignment: .center) {
                    ValueWithUnit(value: percentText, unit: "%", font: AppFont.value)
                    Spacer(minLength: Spacing.xs)
                    if let ratio = statistics.blockRatio {
                        ProgressRing(fraction: ratio, tint: AppColor.blocked)
                    }
                }
                Text("aller Anfragen")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Blockierungsquote")
        .accessibilityValue(statistics.blockRatio.map { $0.formatted(.percent.precision(.fractionLength(1))) }
                            ?? String(localized: "nicht verfügbar"))
    }

    private var percentText: String {
        guard let ratio = statistics.blockRatio else { return "–" }
        return (ratio * 100).formatted(.number.precision(.fractionLength(1)))
    }
}

/// Activity-ring style progress indicator.
private struct ProgressRing: View {
    let fraction: Double
    let tint: Color

    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 40
    @ScaledMetric(relativeTo: .title) private var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .padding(lineWidth / 2)
        .accessibilityHidden(true)
    }
}

private struct ResponseTimeCard: View {
    let averageResponseTime: Duration?

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                CardHeader("Antwortzeit", systemImage: "bolt.fill", tint: AppColor.performance)
                ValueWithUnit(value: millisecondsText, unit: "ms", font: AppFont.value)
                Text("Durchschnitt pro Anfrage")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Durchschnittliche Antwortzeit")
        .accessibilityValue(averageResponseTime.map { _ in "\(millisecondsText) Millisekunden" }
                            ?? String(localized: "nicht verfügbar"))
    }

    private var millisecondsText: String {
        averageResponseTime?.formattedMilliseconds ?? "–"
    }
}
