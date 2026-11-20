import SwiftUI

/// Screen Time–style "most used" card with a segmented control.
struct TopListsCard: View {
    enum Category: CaseIterable, Identifiable {
        case domains, blocked, clients

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .domains: "Domains"
            case .blocked: "Blockiert"
            case .clients: "Clients"
            }
        }

        var tint: Color {
            switch self {
            case .domains: AppColor.protection
            case .blocked: AppColor.blocked
            case .clients: AppColor.network
            }
        }

        func entries(in statistics: DashboardStatistics) -> [RankedEntry] {
            switch self {
            case .domains: statistics.topQueriedDomains
            case .blocked: statistics.topBlockedDomains
            case .clients: statistics.topClients
            }
        }
    }

    static let maxEntries = 5

    let statistics: DashboardStatistics
    @State private var category: Category = .domains

    private var entries: ArraySlice<RankedEntry> {
        category.entries(in: statistics).prefix(Self.maxEntries)
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                CardHeader("Häufigste Anfragen", systemImage: "list.number", tint: AppColor.network)
                Picker("Kategorie", selection: $category) {
                    ForEach(Category.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                if entries.isEmpty {
                    Text("Keine Daten im Zeitraum")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: Metrics.emptyStateHeight)
                } else {
                    VStack(spacing: 0) {
                        ForEach(entries) { entry in
                            TopEntryRow(entry: entry, fraction: fraction(for: entry), category: category)
                            if entry.id != entries.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .animation(.snappy, value: category)
        .sensoryFeedback(.selection, trigger: category)
    }

    private func fraction(for entry: RankedEntry) -> Double {
        guard let maxCount = entries.first?.count, maxCount > 0 else { return 0 }
        return Double(entry.count) / Double(maxCount)
    }
}

private struct TopEntryRow: View {
    let entry: RankedEntry
    let fraction: Double
    let category: TopListsCard.Category

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs + Spacing.xxs) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.name)
                    .font(category == .clients ? AppFont.technical : .subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: Spacing.s)
                Text(entry.count.formatted())
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Capsule()
                .fill(AppColor.fill)
                .frame(height: Metrics.rankBarHeight)
                .overlay(alignment: .leading) {
                    Capsule().fill(category.tint.gradient)
                        .scaleEffect(x: fraction, y: 1, anchor: .leading)
                }
        }
        .padding(.vertical, Spacing.s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.name)
        .accessibilityValue("\(entry.count.formatted()) Anfragen")
    }
}
