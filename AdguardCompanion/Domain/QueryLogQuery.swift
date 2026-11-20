import Foundation

/// Result categories offered as filter, mapped to the documented
/// `FilteringReason` values of the `reason` query parameter.
nonisolated enum QueryLogFilter: String, CaseIterable, Identifiable, Sendable {
    case all, blocked, allowed, rewritten

    var id: Self { self }

    var reasons: [String] {
        switch self {
        case .all:
            []
        case .blocked:
            ["FilteredBlackList", "FilteredSafeBrowsing", "FilteredParental",
             "FilteredInvalid", "FilteredBlockedService"]
        case .allowed:
            ["NotFilteredNotFound", "NotFilteredWhiteList"]
        case .rewritten:
            ["Rewrite", "RewriteEtcHosts", "RewriteRule", "FilteredSafeSearch"]
        }
    }
}

/// Parameters for one page of the query log.
nonisolated struct QueryLogQuery: Equatable, Sendable {
    static let pageSize = 50

    var search: String = ""
    var filter: QueryLogFilter = .all
    /// `oldest` timestamp of the previous page; `nil` for the first page.
    var cursor: String?
    var limit: Int = pageSize

    var trimmedSearch: String {
        search.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Search term for an exact match. AdGuard Home treats a term enclosed in
    /// double quotes as strict: domain, client IP, ClientID or client name must
    /// equal it (internal/querylog/searchcriterion.go). Without quotes,
    /// "192.168.1.1" would also match "192.168.1.10".
    static func exactTerm(_ value: String) -> String {
        "\"\(value)\""
    }

    /// The unquoted term and whether it is an exact match.
    static func parse(_ term: String) -> (value: String, isExact: Bool) {
        guard term.count >= 2, term.hasPrefix("\""), term.hasSuffix("\"") else { return (term, false) }
        return (String(term.dropFirst().dropLast()), true)
    }
}

/// One loaded page of the query log.
nonisolated struct QueryLogPage: Equatable, Sendable {
    let entries: [QueryLogEntry]
    /// Cursor for the next page, or `nil` when the end of the log is reached.
    let nextCursor: String?
}
