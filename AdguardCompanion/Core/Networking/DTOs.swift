import Foundation

// Wire models of the AdGuard Home API (openapi.yaml). All fields are optional
// so that missing or version-dependent fields never break decoding; mappers
// decide how absent values are presented.

/// `components/schemas/ServerStatus`
nonisolated struct ServerStatusDTO: Decodable, Sendable {
    let version: String?
    let running: Bool?
    let protectionEnabled: Bool?
    /// Remaining protection pause in milliseconds.
    let protectionDisabledDuration: Int64?
    let dnsAddresses: [String]?
    let dnsPort: Int?
    let httpPort: Int?
    /// Web API start time, Unix time in milliseconds.
    let startTime: Double?
}

/// `components/schemas/Stats`
nonisolated struct StatsDTO: Decodable, Sendable {
    let timeUnits: String?
    let numDnsQueries: Int?
    let numBlockedFiltering: Int?
    let numReplacedSafebrowsing: Int?
    let numReplacedSafesearch: Int?
    let numReplacedParental: Int?
    /// Average processing time in seconds.
    let avgProcessingTime: Double?
    /// Each entry is a single-key object: `{ "<domain or client>": <count> }`.
    let topQueriedDomains: [[String: Double]]?
    let topClients: [[String: Double]]?
    let topBlockedDomains: [[String: Double]]?
    let dnsQueries: [Int]?
    let blockedFiltering: [Int]?
    let replacedSafebrowsing: [Int]?
    let replacedParental: [Int]?
}

/// `components/schemas/Error`
nonisolated struct ErrorDTO: Decodable, Sendable {
    let message: String?
}
