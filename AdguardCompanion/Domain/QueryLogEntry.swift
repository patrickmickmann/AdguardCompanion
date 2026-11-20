import Foundation

/// A single DNS query from the AdGuard Home query log.
nonisolated struct QueryLogEntry: Identifiable, Equatable, Sendable {
    let id: String
    let date: Date
    /// Domain as shown to people (Unicode for IDNs).
    let domain: String
    /// DNS record type, e.g. "A", "AAAA", "HTTPS".
    let queryType: String?
    let client: QueryClient
    let outcome: QueryOutcome
    let rules: [AppliedRule]
    /// Blocked service name if `outcome` is a blocked service.
    let serviceName: String?
    /// DNS response code, e.g. "NOERROR", "NXDOMAIN".
    let responseStatus: String?
    let answers: [DNSAnswerRecord]
    let upstream: String?
    let isCached: Bool
    let isDNSSECAuthenticated: Bool
    let elapsed: Duration?
    /// Encrypted protocol used by the client ("doh", "dot", "doq", "dnscrypt"), if any.
    let clientProtocol: String?
}

nonisolated struct QueryClient: Equatable, Sendable {
    let address: String
    /// Persistent client name or runtime hostname; `nil` if unknown.
    let name: String?
    /// WHOIS organization, if any.
    let organization: String?

    /// Readable device name without router suffixes, falling back to the IP address.
    var displayName: String { DeviceName.readable(name) ?? address }

    /// Identifies the device across its addresses: a dual-stack device sends
    /// A queries via IPv4 and AAAA queries via IPv6 under the same name.
    var deviceKey: String { name ?? address }
}

nonisolated struct AppliedRule: Equatable, Sendable {
    let text: String
    let filterListID: Int?
}

nonisolated struct DNSAnswerRecord: Equatable, Sendable {
    let type: String
    let value: String
    let ttl: Int?
}
