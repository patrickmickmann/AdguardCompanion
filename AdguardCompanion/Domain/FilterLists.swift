import Foundation

/// A filter list subscription: a blocklist or an allowlist.
nonisolated struct FilterList: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable, CaseIterable {
        case blocklist, allowlist

        var isAllowlist: Bool { self == .allowlist }
    }

    let id: Int
    let name: String
    let url: String
    let kind: Kind
    let isEnabled: Bool
    let ruleCount: Int
    let lastUpdated: Date?

    func with(isEnabled: Bool) -> FilterList {
        FilterList(id: id, name: name, url: url, kind: kind, isEnabled: isEnabled,
                   ruleCount: ruleCount, lastUpdated: lastUpdated)
    }
}

/// Filter list settings of the server.
nonisolated struct FilterListSettings: Equatable, Sendable {
    /// Whether filter lists and user rules are applied at all (`FilterConfig.enabled`).
    let isFilteringEnabled: Bool
    /// Update interval in hours; sent back unchanged when switching filtering.
    let updateIntervalHours: Int
    let lists: [FilterList]

    func lists(of kind: FilterList.Kind) -> [FilterList] {
        lists.filter { $0.kind == kind }
    }

    func list(withURL url: String, kind: FilterList.Kind) -> FilterList? {
        lists.first { $0.url == url && $0.kind == kind }
    }
}

/// One change to the filter list settings.
nonisolated enum FilterListChange: Equatable, Sendable {
    case setFilteringEnabled(Bool)
    case setEnabled(FilterList, Bool)
    case add(name: String, url: String, kind: FilterList.Kind)
    case remove(FilterList)

    /// Whether settings read back from the server show this change.
    func isConfirmed(by settings: FilterListSettings) -> Bool {
        switch self {
        case let .setFilteringEnabled(isOn): settings.isFilteringEnabled == isOn
        case let .setEnabled(list, isOn): settings.list(withURL: list.url, kind: list.kind)?.isEnabled == isOn
        case let .add(_, url, kind): settings.list(withURL: url, kind: kind) != nil
        case let .remove(list): settings.list(withURL: list.url, kind: list.kind) == nil
        }
    }
}

/// Validates input for a new filter list before anything is sent.
nonisolated enum FilterListInput {
    enum Problem: Equatable, Sendable {
        case missingName, invalidURL, duplicate
    }

    /// AdGuard Home accepts http(s) URLs and absolute file paths on the server.
    static func normalizedSource(_ input: String) -> String? {
        let source = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if source.hasPrefix("/") { return source.count > 1 ? source : nil }
        guard let components = URLComponents(string: source),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty, !source.contains(" ") else { return nil }
        return source
    }

    static func problem(name: String, source: String, kind: FilterList.Kind,
                        existing: FilterListSettings?) -> Problem? {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .missingName }
        guard let source = normalizedSource(source) else { return .invalidURL }
        if existing?.list(withURL: source, kind: kind) != nil { return .duplicate }
        return nil
    }
}

nonisolated enum FilterListMapper {
    static func map(_ dto: FilterStatusDTO) -> FilterListSettings {
        func lists(_ items: [FilterDTO]?, kind: FilterList.Kind) -> [FilterList] {
            (items ?? []).compactMap { item in
                guard let id = item.id, let url = item.url else { return nil }
                return FilterList(
                    id: id, name: item.name.flatMap { $0.isEmpty ? nil : $0 } ?? url, url: url, kind: kind,
                    isEnabled: item.enabled ?? false, ruleCount: item.rulesCount ?? 0,
                    lastUpdated: item.lastUpdated.flatMap(date(from:))
                )
            }
        }
        return FilterListSettings(
            isFilteringEnabled: dto.enabled ?? false,
            updateIntervalHours: dto.interval ?? 24,
            lists: lists(dto.filters, kind: .blocklist) + lists(dto.whitelistFilters, kind: .allowlist)
        )
    }

    static func date(from string: String) -> Date? {
        (try? Date(string, strategy: .iso8601))
            ?? (try? Date(string, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
    }
}
