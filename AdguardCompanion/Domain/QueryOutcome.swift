import Foundation

/// What AdGuard Home did with a query, derived from `FilteringReason`.
nonisolated enum QueryOutcome: Equatable, Sendable {
    enum BlockKind: Equatable, Sendable {
        case filterRule, safeBrowsing, parentalControl, blockedService, invalid
    }

    enum RewriteKind: Equatable, Sendable {
        case rewrite, hostsFile, safeSearch
    }

    /// Processed normally, no rule matched.
    case allowed
    /// Explicitly allowed by an allowlist rule.
    case allowlisted
    case blocked(BlockKind)
    case rewritten(RewriteKind)
    /// Filtering failed (`NotFilteredError`).
    case failed
    /// A reason this app version does not know yet.
    case unknown(String)

    init(reason: String?) {
        switch reason {
        case "NotFilteredNotFound", nil, "": self = .allowed
        case "NotFilteredWhiteList": self = .allowlisted
        case "NotFilteredError": self = .failed
        case "FilteredBlackList": self = .blocked(.filterRule)
        case "FilteredSafeBrowsing": self = .blocked(.safeBrowsing)
        case "FilteredParental": self = .blocked(.parentalControl)
        case "FilteredBlockedService": self = .blocked(.blockedService)
        case "FilteredInvalid": self = .blocked(.invalid)
        case "Rewrite", "RewriteRule": self = .rewritten(.rewrite)
        case "RewriteEtcHosts": self = .rewritten(.hostsFile)
        case "FilteredSafeSearch": self = .rewritten(.safeSearch)
        case let .some(other): self = .unknown(other)
        }
    }

    var isBlocked: Bool {
        if case .blocked = self { return true }
        return false
    }
}

/// Resolves `filter_list_id` values to human-readable names.
/// Negative and zero IDs are AdGuard Home's built-in sources
/// (internal/filtering/rulelist: APIIDCustom … APIIDSafeSearch).
nonisolated struct FilterListCatalog: Equatable, Sendable {
    let names: [Int: String]

    static let builtIn: [Int: String] = [
        0: "Benutzerdefinierte Regeln",
        -1: "Hosts-Datei des Systems",
        -2: "Gesperrte Dienste",
        -3: "Kindersicherung",
        -4: "Safe Browsing",
        -5: "Safe Search",
    ]

    init(names: [Int: String]) {
        self.names = names
    }

    init(_ dto: FilterStatusDTO) {
        let lists = (dto.filters ?? []) + (dto.whitelistFilters ?? [])
        var names: [Int: String] = [:]
        for list in lists {
            guard let id = list.id, let name = list.name, !name.isEmpty else { continue }
            names[id] = name
        }
        self.names = names
    }

    func name(for id: Int?) -> String? {
        guard let id else { return nil }
        return Self.builtIn[id] ?? names[id]
    }
}
