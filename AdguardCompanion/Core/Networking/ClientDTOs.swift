import Foundation

// Wire models for `/control/clients` and `/control/blocked_services/all`
// (openapi.yaml: Clients, Client, ClientAuto, SafeSearchConfig,
// BlockedServicesAll, BlockedService). All fields optional.

/// `components/schemas/Clients`
nonisolated struct ClientsDTO: Decodable, Sendable {
    let clients: [PersistentClientDTO]?
    let autoClients: [RuntimeClientDTO]?
}

/// `components/schemas/Client`
nonisolated struct PersistentClientDTO: Decodable, Sendable {
    let name: String?
    /// IP, CIDR, MAC or ClientID.
    let ids: [String]?
    let useGlobalSettings: Bool?
    let filteringEnabled: Bool?
    let parentalEnabled: Bool?
    let safebrowsingEnabled: Bool?
    let safeSearch: SafeSearchConfigDTO?
    let useGlobalBlockedServices: Bool?
    let blockedServices: [String]?
    let upstreams: [String]?
    let tags: [String]?
    let ignoreQuerylog: Bool?
    let ignoreStatistics: Bool?
}

/// `components/schemas/SafeSearchConfig` (only the master switch is used).
nonisolated struct SafeSearchConfigDTO: Decodable, Sendable {
    let enabled: Bool?
}

/// `components/schemas/ClientAuto`
nonisolated struct RuntimeClientDTO: Decodable, Sendable {
    let ip: String?
    let name: String?
    /// "WHOIS", "ARP", "rDNS", "DHCP" or "etc/hosts".
    let source: String?
    let whoisInfo: [String: String]?
}

/// `components/schemas/BlockedServicesAll` (icons are not used).
nonisolated struct BlockedServicesAllDTO: Decodable, Sendable {
    let blockedServices: [BlockedServiceDTO]?
}

nonisolated struct BlockedServiceDTO: Decodable, Sendable {
    let id: String?
    let name: String?
}
