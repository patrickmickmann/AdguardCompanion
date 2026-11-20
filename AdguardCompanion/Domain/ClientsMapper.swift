import Foundation

/// Maps `/control/clients` to domain models and joins request counts
/// from the statistics' top clients (keyed by IP address or name).
nonisolated enum ClientsMapper {
    static func map(_ dto: ClientsDTO, topClients: [RankedEntry]) -> [NetworkClient] {
        let counts = Dictionary(topClients.map { ($0.name, $0.count) }, uniquingKeysWith: +)

        let configured = (dto.clients ?? []).compactMap { item -> NetworkClient? in
            guard let name = item.name, !name.isEmpty else { return nil }
            let ids = item.ids ?? []
            return NetworkClient(
                name: name, identifiers: ids, kind: .configured(settings(from: item)),
                whois: [:], requestCount: requestCount(for: ids + [name], in: counts)
            )
        }
        let configuredIDs = Set(configured.flatMap(\.identifiers))

        let discovered = (dto.autoClients ?? []).compactMap { item -> NetworkClient? in
            guard let ip = item.ip, !ip.isEmpty, !configuredIDs.contains(ip) else { return nil }
            let name = DeviceName.readable(item.name) ?? ip
            return NetworkClient(
                name: name, identifiers: [ip], kind: .discovered(source: DiscoverySource(item.source)),
                whois: item.whoisInfo ?? [:], requestCount: counts[ip]
            )
        }
        return sorted(configured + mergingDualStack(discovered))
    }

    /// AdGuard Home lists a discovered device once per address. Addresses of one
    /// dual-stack device share the resolved name and are merged into one client.
    /// Distinct devices can share a name too (two "iPhone"s), so a client gets at
    /// most one IPv4 address, and IPv6 addresses are only attached when exactly
    /// one device carries that name. Unnamed clients are never merged.
    static func mergingDualStack(_ clients: [NetworkClient]) -> [NetworkClient] {
        func isIPv6(_ client: NetworkClient) -> Bool { client.identifiers.first?.contains(":") ?? false }
        var groups: [NetworkClient] = []
        for client in clients.filter({ !isIPv6($0) }) + clients.filter(isIPv6) {
            let candidates = client.hasName ? groups.indices.filter { groups[$0].name == client.name } : []
            let target: Int? = isIPv6(client)
                ? (candidates.count == 1 ? candidates[0] : nil)
                : candidates.first { index in !groups[index].identifiers.contains { !$0.contains(":") } }
            guard let target else {
                groups.append(client)
                continue
            }
            groups[target] = merged(groups[target], client)
        }
        return groups
    }

    private static func merged(_ existing: NetworkClient, _ client: NetworkClient) -> NetworkClient {
        let total = [existing.requestCount, client.requestCount].compactMap(\.self)
        return NetworkClient(
            name: existing.name, identifiers: existing.identifiers + client.identifiers, kind: existing.kind,
            whois: existing.whois.merging(client.whois) { first, _ in first },
            requestCount: total.isEmpty ? nil : total.reduce(0, +)
        )
    }

    /// Named clients alphabetically, unnamed ones afterwards by address.
    static func sortedByName(_ clients: [NetworkClient]) -> [NetworkClient] {
        clients.sorted { lhs, rhs in
            if lhs.hasName != rhs.hasName { return lhs.hasName }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    /// Most active first; clients without statistics afterwards, alphabetically.
    static func sorted(_ clients: [NetworkClient]) -> [NetworkClient] {
        clients.sorted { lhs, rhs in
            switch (lhs.requestCount, rhs.requestCount) {
            case let (left?, right?) where left != right: left > right
            case (.some, nil): true
            case (nil, .some): false
            default: lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
    }

    private static func requestCount(for keys: [String], in counts: [String: Int]) -> Int? {
        let matches = Set(keys).compactMap { counts[$0] }
        return matches.isEmpty ? nil : matches.reduce(0, +)
    }

    private static func settings(from item: PersistentClientDTO) -> ClientSettings {
        ClientSettings(
            usesGlobalSettings: item.useGlobalSettings ?? true,
            filteringEnabled: item.filteringEnabled ?? false,
            safeBrowsingEnabled: item.safebrowsingEnabled ?? false,
            parentalControlEnabled: item.parentalEnabled ?? false,
            safeSearchEnabled: item.safeSearch?.enabled ?? false,
            usesGlobalBlockedServices: item.useGlobalBlockedServices ?? true,
            blockedServiceIDs: item.blockedServices ?? [],
            upstreams: (item.upstreams ?? []).filter { !$0.isEmpty },
            tags: item.tags ?? [],
            excludedFromQueryLog: item.ignoreQuerylog ?? false,
            excludedFromStatistics: item.ignoreStatistics ?? false
        )
    }
}
