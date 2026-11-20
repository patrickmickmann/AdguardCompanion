import SwiftUI
import UIKit

/// Full technical detail of one query, prioritized: what happened first,
/// then request, filtering and response.
struct QueryDetailScreen: View {
    let group: QueryLogGroup
    let model: ActivityModel
    @State private var ruleModel: DomainRuleModel

    init(group: QueryLogGroup, model: ActivityModel) {
        self.group = group
        self.model = model
        _ruleModel = State(initialValue: model.makeRuleModel(for: group.primary))
    }

    private var entry: QueryLogEntry { group.primary }

    @ScaledMetric(relativeTo: .largeTitle) private var badgeSize: CGFloat = 56

    var body: some View {
        List {
            Section {
                header
            }
            if ruleModel.isEditable {
                DomainRuleSection(model: ruleModel)
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
        .task { await ruleModel.load() }
        .domainRuleDialogs(ruleModel)
    }

    private var header: some View {
        VStack(spacing: Spacing.s) {
            OutcomeBadge(outcome: entry.outcome, size: badgeSize)
            Text(DomainDisplayParts.wrappable(entry.domain))
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityLabel(entry.domain)
            Text(entry.outcome.detail)
                .font(.subheadline)
                .foregroundStyle(entry.outcome.tint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
        .accessibilityElement(children: .combine)
        .contextMenu {
            Button("Domain kopieren", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = entry.domain
            }
        }
    }
}
