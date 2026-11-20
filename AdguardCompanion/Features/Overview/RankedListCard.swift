import SwiftUI

/// Top-N list (domains or clients) with relative bars.
struct RankedListCard: View {
    enum Style { case domain, client }

    static let maxEntries = 5

    let title: LocalizedStringKey
    let entries: [RankedEntry]
    let tone: StatusTone
    let style: Style

    private var visibleEntries: ArraySlice<RankedEntry> { entries.prefix(Self.maxEntries) }
    private var maxCount: Int { visibleEntries.map(\.count).max() ?? 0 }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                CardHeader(title: title)
                if visibleEntries.isEmpty {
                    Text("Keine Daten im Zeitraum")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(visibleEntries) { entry in
                        RankedRow(entry: entry, fraction: fraction(for: entry), tone: tone, style: style)
                    }
                }
            }
        }
    }

    private func fraction(for entry: RankedEntry) -> Double {
        maxCount > 0 ? Double(entry.count) / Double(maxCount) : 0
    }
}

private struct RankedRow: View {
    let entry: RankedEntry
    let fraction: Double
    let tone: StatusTone
    let style: RankedListCard.Style

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                Text(entry.name)
                    .font(style == .client ? AppFont.technical : .subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: Spacing.s)
                Text(entry.count.formatted())
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            bar
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.name)
        .accessibilityValue("\(entry.count.formatted()) Anfragen")
    }

    private var bar: some View {
        Capsule()
            .fill(AppColor.surfaceRaised)
            .frame(height: Metrics.rankBarHeight)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(tone.color.opacity(0.8))
                    .scaleEffect(x: fraction, y: 1, anchor: .leading)
            }
    }
}
