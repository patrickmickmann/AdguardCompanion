import SwiftUI

/// Read-only client detail: identifiers, activity and effective protection,
/// clearly distinguishing global from individual settings.
struct ClientDetailScreen: View {
    let client: NetworkClient
    let model: ClientsModel

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 64

    var body: some View {
        List {
            Section { header }
            Section("Kennungen") {
                ForEach(client.sortedIdentifiers, id: \.self) { identifier in
                    Text(identifier)
                        .font(AppFont.technical)
                        .textSelection(.enabled)
                }
            }
            activitySection
            switch client.kind {
            case let .configured(settings):
                ClientProtectionSection(settings: settings)
                ClientRoutingSection(settings: settings, serviceNames: model.serviceNames)
            case let .discovered(source):
                ClientDiscoverySection(source: source, whois: client.whois)
            }
        }
        .navigationTitle(client.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadServiceNamesIfNeeded() }
    }

    private var header: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: client.symbol)
                .font(.system(size: iconSize * 0.45, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)
                .background((client.isConfigured ? AppColor.network : Color.gray).gradient, in: .circle)
                .accessibilityHidden(true)
            Text(client.displayTitle)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(client.isConfigured ? "Eingerichteter Client" : "Automatisch erkannt")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
        .accessibilityElement(children: .combine)
    }

    private var activitySection: some View {
        Section {
            LabeledContent("Anfragen im Zeitraum") {
                Text(client.requestCount?.formatted() ?? "Keine Angabe")
            }
            ClientLastActivityRow(client: client, model: model)
            if let address = client.searchableAddress {
                NavigationLink {
                    ActivityScreen(repository: model.repository, initialSearch: QueryLogQuery.exactTerm(address),
                                   title: client.displayTitle)
                } label: {
                    Label("Anfragen im Query-Log", systemImage: "list.bullet.rectangle")
                }
            }
        } header: {
            Text("Aktivität")
        } footer: {
            if client.requestCount == nil {
                Text("Die Statistik enthält nur die aktivsten Clients des Zeitraums.")
            }
        }
    }
}
