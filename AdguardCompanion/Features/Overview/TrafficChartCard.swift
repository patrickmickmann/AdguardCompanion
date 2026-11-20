import Charts
import SwiftUI

/// Stacked area chart of allowed and blocked requests over the statistics period.
struct TrafficChartCard: View {
    let statistics: DashboardStatistics

    private enum Series: String, Plottable {
        case allowed = "Erlaubt"
        case blocked = "Blockiert"
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                CardHeader(title: "DNS-Anfragen", subtitle: LocalizedStringKey(statistics.period.localizedDescription))
                if statistics.hasTraffic {
                    chart
                } else {
                    Text("Keine Anfragen im Zeitraum")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: Metrics.chartHeight)
                }
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(statistics.traffic) { bucket in
                AreaMark(
                    x: .value("Zeit", bucket.start, unit: xUnit),
                    y: .value("Anfragen", bucket.blocked),
                    stacking: .standard
                )
                .foregroundStyle(by: .value("Ergebnis", Series.blocked))
                AreaMark(
                    x: .value("Zeit", bucket.start, unit: xUnit),
                    y: .value("Anfragen", bucket.allowed),
                    stacking: .standard
                )
                .foregroundStyle(by: .value("Ergebnis", Series.allowed))
            }
            .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale([
            Series.allowed: AppColor.protection.opacity(0.75),
            Series.blocked: AppColor.blocked.opacity(0.85),
        ])
        .chartXAxis {
            AxisMarks(values: axisDates) { _ in
                AxisGridLine()
                AxisValueLabel(format: xAxisFormat, centered: false)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartLegend(position: .bottom, alignment: .leading, spacing: Spacing.m)
        .frame(height: Metrics.chartHeight)
        .accessibilityLabel("Verlauf der DNS-Anfragen, \(statistics.period.localizedDescription)")
    }

    private var xUnit: Calendar.Component {
        statistics.period.unit == .hour ? .hour : .day
    }

    /// Axis labels on round times: every 6 hours (00, 06, 12, 18) or about four days.
    private var axisDates: [Date] {
        let starts = statistics.traffic.map(\.start)
        switch statistics.period.unit {
        case .hour:
            return starts.filter { Calendar.current.component(.hour, from: $0) % 6 == 0 }
        case .day:
            let step = max(1, starts.count / 4)
            return starts.enumerated().filter { $0.offset % step == 0 }.map(\.element)
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        statistics.period.unit == .hour
            // Locale-aware: "18:00" in 24-hour locales, "6 PM" in 12-hour locales.
            ? .dateTime.hour()
            : .dateTime.day().month(.twoDigits)
    }
}
