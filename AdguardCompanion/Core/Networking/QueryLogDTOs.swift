import Foundation

// Wire models for `/control/querylog` and `/control/filtering/status`
// (openapi.yaml: QueryLog, QueryLogItem, DnsQuestion, DnsAnswer, ResultRule,
// QueryLogItemClient, FilterStatus, Filter). All fields optional.

/// `components/schemas/QueryLog`
nonisolated struct QueryLogDTO: Decodable, Sendable {
    /// Timestamp of the oldest returned entry; used as `older_than` cursor.
    let oldest: String?
    let data: [QueryLogItemDTO]?
}

/// `components/schemas/QueryLogItem`
nonisolated struct QueryLogItemDTO: Decodable, Sendable {
    let answer: [DNSAnswerDTO]?
    let cached: Bool?
    let upstream: String?
    let answerDnssec: Bool?
    let client: String?
    let clientInfo: QueryLogClientDTO?
    let clientProto: String?
    /// Processing time in milliseconds, encoded as a string.
    let elapsedMs: String?
    let question: DNSQuestionDTO?
    let rules: [ResultRuleDTO]?
    let reason: String?
    let serviceName: String?
    let status: String?
    /// RFC 3339 timestamp with nanoseconds.
    let time: String?
}

nonisolated struct DNSQuestionDTO: Decodable, Sendable {
    let `class`: String?
    let name: String?
    let unicodeName: String?
    let type: String?
}

nonisolated struct DNSAnswerDTO: Decodable, Sendable {
    let ttl: Int?
    let type: String?
    let value: String?
}

nonisolated struct ResultRuleDTO: Decodable, Sendable {
    let filterListId: Int?
    let text: String?
}

nonisolated struct QueryLogClientDTO: Decodable, Sendable {
    let name: String?
    let whois: QueryLogWhoisDTO?
}

nonisolated struct QueryLogWhoisDTO: Decodable, Sendable {
    let city: String?
    let country: String?
    let orgname: String?
}

/// `components/schemas/FilterStatus`
nonisolated struct FilterStatusDTO: Decodable, Sendable {
    let enabled: Bool?
    let filters: [FilterDTO]?
    let whitelistFilters: [FilterDTO]?
    let userRules: [String]?
}

/// `components/schemas/SetRulesRequest`
nonisolated struct SetRulesRequestDTO: Encodable, Sendable {
    let rules: [String]
}

/// `components/schemas/Filter`
nonisolated struct FilterDTO: Decodable, Sendable {
    let id: Int?
    let name: String?
    let enabled: Bool?
    let rulesCount: Int?
}
