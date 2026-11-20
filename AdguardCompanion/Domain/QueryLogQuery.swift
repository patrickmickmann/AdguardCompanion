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
}

/// One loaded page of the query log.
nonisolated struct QueryLogPage: Equatable, Sendable {
    let entries: [QueryLogEntry]
    /// Cursor for the next page, or `nil` when the end of the log is reached.
    let nextCursor: String?
}
