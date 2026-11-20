import SwiftUI

/// Full technical detail of one query, prioritized: what happened first,
/// then request, filtering and response.
struct QueryDetailScreen: View {
    let group: QueryLogGroup
    let model: ActivityModel

    private var entry: QueryLogEntry { group.primary }

    @ScaledMetric(relativeTo: .largeTitle) private var badgeSize: CGFloat = 56

    var body: some View {
        List {
            Section {
                header
            }
            QueryRequestSection(group: group)
            if entry.outcome != .allowed || !entry.rules.isEmpty {
                QueryFilteringSection(entry: entry, catalog: model.catalog, catalogError: model.catalogError)
            }
            QueryResponseSection(group: group)
        }
        .navigationTitle("Anfrage")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadCatalogIfNeeded() }
    }

    private var header: some View {
        VStack(spacing: Spacing.s) {
            OutcomeBadge(outcome: entry.outcome, size: badgeSize)
            Text(entry.domain)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
            Text(entry.outcome.detail)
                .font(.subheadline)
                .foregroundStyle(entry.outcome.tint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
        .accessibilityElement(children: .combine)
    }
}
