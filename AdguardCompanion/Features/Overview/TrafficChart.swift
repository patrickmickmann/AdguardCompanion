import Charts
import SwiftUI

/// Stacked bars of blocked (base) and allowed requests per hour or day,
/// with scrubbing, a dashed average line and haptic feedback.
struct TrafficChart: View {
    let statistics: DashboardStatistics
    @Binding var selectedDate: Date?

    private enum Series: String, Plottable {
        case allowed = "Erlaubt"
        case blocked = "Blockiert"
    }

    private var selectedBucket: TrafficBucket? {
        selectedDate.flatMap(statistics.bucket(containing:))
    }

    var body: some View {
        Chart {
            ForEach(statistics.traffic) { bucket in
                bar(for: bucket, value: bucket.blocked, series: .blocked)
                bar(for: bucket, value: bucket.allowed, series: .allowed)
            }
            if selectedBucket == nil, let average = statistics.averageQueriesPerBucket {
                RuleMark(y: .value("Durchschnitt", average))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .annotation(position: .top, alignment: .leading, spacing: Spacing.xxs) {
                        Text("Ø").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    }
            }
        }
        .chartForegroundStyleScale([Series.allowed: AppColor.protection, Series.blocked: AppColor.blocked])
        .chartLegend(.hidden)
        .chartXSelection(value: $selectedDate)
        .chartXAxis {
            AxisMarks(values: axisDates) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                AxisValueLabel(format: axisFormat, centered: false)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                AxisValueLabel(format: IntegerFormatStyle<Int>().notation(.compactName))
            }
        }
        .frame(height: Metrics.chartHeight)
        .sensoryFeedback(.selection, trigger: selectedBucket?.id)
        .animation(.snappy, value: selectedBucket?.id)
        .accessibilityLabel("Verlauf der DNS-Anfragen, \(statistics.period.localizedDescription)")
    }

    private func bar(for bucket: TrafficBucket, value: Int, series: Series) -> some ChartContent {
        BarMark(
            x: .value("Zeit", bucket.start, unit: unit),
            y: .value("Anfragen", value)
        )
        .foregroundStyle(by: .value("Ergebnis", series))
        .cornerRadius(Metrics.barCornerRadius)
        .opacity(selectedBucket == nil || selectedBucket == bucket ? 1 : 0.3)
    }

    private var unit: Calendar.Component {
        statistics.period.unit == .hour ? .hour : .day
    }

    /// Labels on round times: every 6 hours, or about four labels for days.
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

    private var axisFormat: Date.FormatStyle {
        statistics.period.unit == .hour ? .dateTime.hour() : .dateTime.day().month(.abbreviated)
    }
}
