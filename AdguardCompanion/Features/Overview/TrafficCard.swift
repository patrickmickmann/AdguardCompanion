import SwiftUI

/// Health-style card: the headline figure follows the user's finger while
/// scrubbing through the chart.
struct TrafficCard: View {
    let statistics: DashboardStatistics

    @State private var selectedDate: Date?

    private var selectedBucket: TrafficBucket? {
        selectedDate.flatMap(statistics.bucket(containing:))
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                CardHeader("DNS-Anfragen", systemImage: "chart.bar.fill", tint: AppColor.protection) {
                    Text(statistics.period.localizedDescription)
                }
                summary
                if statistics.hasTraffic {
                    TrafficChart(statistics: statistics, selectedDate: $selectedDate)
                    TrafficLegend()
                } else {
                    Text("Im Zeitraum wurden keine Anfragen gezählt.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var summary: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if let bucket = selectedBucket {
                ValueWithUnit(value: bucket.total.formatted(), unit: "Anfragen")
                detailLine(blocked: bucket.blocked, suffix: intervalText(for: bucket))
            } else {
                ValueWithUnit(value: statistics.totalQueries?.formatted() ?? "–", unit: "Anfragen")
                if let blocked = statistics.blocked {
                    detailLine(blocked: blocked.total, suffix: nil)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func detailLine(blocked: Int, suffix: String?) -> some View {
        let count = Text(blocked.formatted()).foregroundStyle(AppColor.blocked).fontWeight(.semibold)
        let line = suffix.map { Text("\(count) blockiert · \($0)") } ?? Text("\(count) blockiert")
        return line
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func intervalText(for bucket: TrafficBucket) -> String {
        switch statistics.period.unit {
        case .hour:
            let end = bucket.start.addingTimeInterval(3600)
            return "\(bucket.start.formatted(.dateTime.hour().minute()))–\(end.formatted(.dateTime.hour().minute()))"
        case .day:
            return bucket.start.formatted(.dateTime.weekday(.wide).day().month())
        }
    }
}

/// Compact legend; the chart's own legend is hidden for a cleaner layout.
private struct TrafficLegend: View {
    var body: some View {
        HStack(spacing: Spacing.l) {
            item("Erlaubt", color: AppColor.protection)
            item("Blockiert", color: AppColor.blocked)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }

    private func item(_ title: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
            Text(title)
        }
    }
}
