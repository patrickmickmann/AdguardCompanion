import SwiftUI

/// Key figures for the statistics period: queries, blocked, block ratio and response time.
struct MetricsSection: View {
    let statistics: DashboardStatistics

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Label(statistics.period.localizedDescription, systemImage: "clock")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.leading, Spacing.xs)

            tileStack
            MetricTile(
                systemImage: "stopwatch",
                value: statistics.averageResponseTime.map { Self.format($0) },
                label: "Ø Antwortzeit",
                tone: .neutral,
                layout: .horizontal
            )
        }
    }

    /// Three equal-height tiles side by side; stacked at accessibility text sizes.
    private var tileStack: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.s))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.s))
        return layout {
            MetricTile(
                systemImage: "point.3.connected.trianglepath.dotted",
                value: statistics.totalQueries.map { $0.formatted() },
                label: "Anfragen",
                tone: .positive
            )
            MetricTile(
                systemImage: "hand.raised.fill",
                value: statistics.blocked.map { $0.total.formatted() },
                label: "Blockiert",
                tone: .critical
            )
            MetricTile(
                systemImage: "chart.pie.fill",
                value: statistics.blockRatio.map { $0.formatted(.percent.precision(.fractionLength(1))) },
                // Soft hyphen allows "Blockierungs-quote" to break at the word joint.
                label: "Blockierungs\u{00AD}quote",
                tone: .positive
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private static func format(_ duration: Duration) -> String {
        duration.formatted(.units(allowed: [.milliseconds], width: .abbreviated))
    }
}

/// Single key figure. A missing value is shown as a dash, never as zero.
struct MetricTile: View {
    enum Layout { case vertical, horizontal }

    let systemImage: String
    let value: String?
    let label: LocalizedStringKey
    let tone: StatusTone
    var layout: Layout = .vertical

    /// Uniform icon box so values line up regardless of symbol proportions.
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22

    var body: some View {
        SurfaceCard(padding: Spacing.m) {
            switch layout {
            case .vertical:
                VStack(alignment: .leading, spacing: Spacing.s) {
                    icon
                    valueText
                    labelText
                    Spacer(minLength: 0)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            case .horizontal:
                HStack(spacing: Spacing.m) {
                    icon
                    labelText
                    Spacer(minLength: Spacing.s)
                    valueText
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value ?? String(localized: "nicht verfügbar"))
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(tone.color)
            .frame(width: iconSize, height: iconSize, alignment: .leading)
    }

    private var valueText: some View {
        Text(value ?? "–")
            .font(AppFont.metricValue)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var labelText: some View {
        Text(label)
            .font(AppFont.metricLabel)
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }
}
