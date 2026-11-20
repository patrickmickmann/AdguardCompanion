import Foundation

/// A service AdGuard Home can block as a whole, e.g. "YouTube".
nonisolated struct BlockableService: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let groupID: String
}

/// The service catalog and which services are blocked globally.
nonisolated struct BlockedServices: Equatable, Sendable {
    let catalog: [BlockableService]
    let blockedIDs: Set<String>
    /// The server's schedule object, sent back unchanged on update.
    let schedule: JSONValue?

    /// Blocked services sorted by name.
    var blocked: [BlockableService] {
        catalog.filter { blockedIDs.contains($0.id) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Catalog grouped by `group_id`, groups and services sorted by name.
    func groups(matching query: String) -> [(id: String, services: [BlockableService])] {
        let query = query.trimmingCharacters(in: .whitespaces)
        let matching = catalog.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
        return Dictionary(grouping: matching, by: \.groupID)
            .map { ($0.key, $0.value.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) }
            .sorted { BlockedServiceGroup.title($0.0).localizedStandardCompare(BlockedServiceGroup.title($1.0)) == .orderedAscending }
    }
}

nonisolated enum BlockedServiceGroup {
    /// German titles for AdGuard Home's service groups; unknown ones are shown as sent.
    static func title(_ id: String) -> String {
        switch id {
        case "ai": "KI"
        case "cdn": "CDN"
        case "dating": "Dating"
        case "gambling": "Glücksspiel"
        case "gaming": "Spiele"
        case "hosting": "Hosting"
        case "messenger": "Messenger"
        case "music": "Musik"
        case "privacy": "Datenschutz"
        case "shopping": "Shopping"
        case "social_network": "Soziale Netzwerke"
        case "software": "Software"
        case "streaming": "Streaming"
        case "": "Sonstige"
        default: id.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

/// Changes the blocked services and confirms them by reading them back.
nonisolated struct BlockedServicesUpdater: Sendable {
    let repository: any AdGuardRepository

    func set(_ ids: Set<String>, current: BlockedServices) async throws(APIError) -> BlockedServices {
        try await repository.setBlockedServices(ids, keeping: current)
        let confirmed = try await repository.fetchBlockedServices()
        guard confirmed.blockedIDs == ids else { throw .changeNotConfirmed }
        return confirmed
    }
}
