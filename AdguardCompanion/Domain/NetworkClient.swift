import Foundation
import Network

/// A device known to AdGuard Home: either configured by the user
/// ("persistent") or discovered automatically ("runtime").
nonisolated struct NetworkClient: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case configured(ClientSettings)
        case discovered(source: DiscoverySource)
    }

    let name: String
    /// IP addresses, CIDRs, MAC addresses or ClientIDs.
    let identifiers: [String]
    let kind: Kind
    /// WHOIS details such as organization or country, if any.
    let whois: [String: String]
    /// Requests in the statistics period; `nil` if the server reported none for this client.
    let requestCount: Int?

    var id: String {
        switch kind {
        case .configured: "configured:\(name)"
        case .discovered: "discovered:\(identifiers.first ?? name)"
        }
    }

    /// `false` when AdGuard Home knows no name and only the address is available.
    var hasName: Bool { !identifiers.contains(name) }

    /// Title for lists: the name, or a neutral label for unnamed devices.
    var displayTitle: String { hasName ? name : String(localized: "Unbekanntes Gerät") }

    var isConfigured: Bool {
        if case .configured = kind { return true }
        return false
    }

    /// First plain IP address, usable as query log search term.
    /// MAC addresses, CIDRs and ClientIDs are not searchable in the query log.
    /// Identifiers for display: IPv4 first, then IPv6, then MACs, CIDRs and ClientIDs.
    var sortedIdentifiers: [String] {
        func rank(_ id: String) -> Int {
            IPv4Address(id) != nil ? 0 : (IPv6Address(id) != nil ? 1 : 2)
        }
        return identifiers.enumerated()
            .sorted { (rank($0.element), $0.offset) < (rank($1.element), $1.offset) }
            .map(\.element)
    }

    /// All plain IP addresses (no MACs, CIDRs or ClientIDs).
    var ipAddresses: [String] {
        sortedIdentifiers.filter { IPv4Address($0) != nil || IPv6Address($0) != nil }
    }

    /// Prefers IPv4, which is easier to recognize than IPv6.
    var searchableAddress: String? {
        identifiers.first { IPv4Address($0) != nil } ?? identifiers.first { IPv6Address($0) != nil }
    }
}

/// Per-client protection settings. Values only apply when the
/// corresponding "use global" flag is off.
nonisolated struct ClientSettings: Hashable, Sendable {
    let usesGlobalSettings: Bool
    let filteringEnabled: Bool
    let safeBrowsingEnabled: Bool
    let parentalControlEnabled: Bool
    let safeSearchEnabled: Bool
    let usesGlobalBlockedServices: Bool
    let blockedServiceIDs: [String]
    /// Empty means the global upstream servers are used.
    let upstreams: [String]
    let tags: [String]
    let excludedFromQueryLog: Bool
    let excludedFromStatistics: Bool
}

/// How AdGuard Home learned about a runtime client.
nonisolated enum DiscoverySource: Hashable, Sendable {
    case whois, arp, reverseDNS, dhcp, hostsFile
    case other(String)

    init(_ raw: String?) {
        switch raw {
        case "WHOIS": self = .whois
        case "ARP": self = .arp
        case "rDNS": self = .reverseDNS
        case "DHCP": self = .dhcp
        case "etc/hosts": self = .hostsFile
        default: self = .other(raw ?? "")
        }
    }
}
