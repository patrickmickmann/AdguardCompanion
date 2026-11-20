import Foundation

/// Applies filter list changes and reports success only after reading the
/// settings back from the server.
nonisolated struct FilterListUpdater: Sendable {
    let repository: any AdGuardRepository

    func apply(_ change: FilterListChange, current: FilterListSettings) async throws(APIError) -> FilterListSettings {
        if case let .add(name, url, kind) = change,
           FilterListInput.problem(name: name, source: url, kind: kind, existing: current) != nil {
            throw .invalidInput
        }
        try await repository.updateFilterLists(change, current: current)
        let settings = try await repository.fetchFilterListSettings()
        guard change.isConfirmed(by: settings) else { throw .changeNotConfirmed }
        return settings
    }

    /// Downloads the latest versions of all enabled lists of both kinds.
    /// Returns the settings afterwards and how many lists changed.
    func refreshAll() async throws(APIError) -> (settings: FilterListSettings, updated: Int) {
        var updated = 0
        for kind in FilterList.Kind.allCases {
            updated += try await repository.refreshFilterLists(kind)
        }
        return (try await repository.fetchFilterListSettings(), updated)
    }
}
