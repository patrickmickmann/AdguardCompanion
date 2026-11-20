import SwiftUI

struct QueryRequestSection: View {
    let group: QueryLogGroup

    private var entry: QueryLogEntry { group.primary }

    var body: some View {
        Section("Anfrage") {
            LabeledContent("Zeitpunkt", value: entry.date.formatted(date: .abbreviated, time: .standard))
            if !group.queryTypes.isEmpty {
                LabeledContent(group.queryTypes.count > 1 ? "Typen" : "Typ") {
                    Text(group.queryTypes.joined(separator: ", ")).font(AppFont.technicalSmall)
                }
            }
            if let name = entry.client.name {
                LabeledContent("Client", value: name)
            }
            LabeledContent(entry.client.name == nil ? "Client" : "IP-Adresse") {
                Text(entry.client.address).font(AppFont.technicalSmall).textSelection(.enabled)
            }
            if let organization = entry.client.organization {
                LabeledContent("Organisation", value: organization)
            }
            if let protocolName = entry.clientProtocol {
                LabeledContent("Protokoll", value: protocolName.uppercased())
            }
        }
    }
}

struct QueryFilteringSection: View {
    let entry: QueryLogEntry
    let catalog: FilterListCatalog?
    let catalogError: APIError?

    var body: some View {
        Section {
            LabeledContent("Ergebnis") {
                Text(entry.outcome.title).foregroundStyle(entry.outcome.tint)
            }
            if let service = entry.serviceName {
                LabeledContent("Dienst", value: service)
            }
            ForEach(Array(entry.rules.enumerated()), id: \.offset) { _, rule in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(rule.text)
                        .font(AppFont.technicalSmall)
                        .textSelection(.enabled)
                    if let listName = listName(for: rule) {
                        Label(listName, systemImage: "list.bullet.rectangle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }
        } header: {
            Text("Filterung")
        } footer: {
            if catalogError != nil, entry.rules.contains(where: { $0.filterListID != nil }) {
                Text("Die Namen der Filterlisten konnten nicht geladen werden.")
            }
        }
    }

    private func listName(for rule: AppliedRule) -> String? {
        guard let id = rule.filterListID else { return nil }
        return catalog?.name(for: id) ?? FilterListCatalog.builtIn[id] ?? "Filterliste \(id)"
    }
}

struct QueryResponseSection: View {
    let group: QueryLogGroup

    private var entry: QueryLogEntry { group.primary }
    /// Answers of all combined queries, e.g. both the A and the AAAA records.
    private var answers: [DNSAnswerRecord] { group.entries.flatMap(\.answers) }

    var body: some View {
        Section("Antwort") {
            if let status = entry.responseStatus {
                LabeledContent("Status") { Text(status).font(AppFont.technicalSmall) }
            }
            if let elapsed = entry.elapsed {
                LabeledContent("Antwortzeit", value: "\(elapsed.formattedPreciseMilliseconds) ms")
            }
            if let upstream = entry.upstream {
                LabeledContent("Upstream") {
                    Text(upstream).font(AppFont.technicalSmall).lineLimit(2).truncationMode(.middle)
                }
            }
            LabeledContent("Aus dem Cache", value: entry.isCached ? "Ja" : "Nein")
            if entry.isDNSSECAuthenticated {
                LabeledContent("DNSSEC", value: "Authentifiziert")
            }
            ForEach(Array(answers.enumerated()), id: \.offset) { _, answer in
                LabeledContent {
                    Text(answer.value).font(AppFont.technicalSmall).textSelection(.enabled)
                } label: {
                    Text(answer.ttl.map { "\(answer.type) · TTL \($0)" } ?? answer.type)
                }
            }
        }
    }
}

extension Duration {
    /// Milliseconds with two decimals below 10 ms, otherwise whole numbers.
    var formattedPreciseMilliseconds: String {
        milliseconds.formatted(.number.precision(.fractionLength(milliseconds < 10 ? 2 : 0)))
    }
}
