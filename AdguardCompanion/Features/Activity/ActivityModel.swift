import Foundation
import Observation

/// Presentation state of the query log: search, filter and cursor-based paging.
/// Entries are kept in memory only and never persisted.
@Observable
final class ActivityModel {
    /// Identity of the current search; a change triggers a reload.
    struct QueryKey: Hashable {
        let search: String
        let filter: QueryLogFilter
    }

    static let searchDebounce: Duration = .milliseconds(350)

    var searchText = ""
    var filter: QueryLogFilter = .all

    private(set) var entries: [QueryLogEntry] = [] {
        didSet { sections = QueryLogGrouping.sections(from: QueryLogGrouping.groups(from: entries), calendar: calendar) }
    }
    /// Entries grouped into per-minute sections of combined requests.
    private(set) var sections: [QueryLogSection] = []
    private(set) var hasLoaded = false
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: APIError?
    private(set) var loadMoreError: APIError?
    private(set) var catalog: FilterListCatalog?
    private(set) var catalogError: APIError?

    let isDemo: Bool
    private let repository: any AdGuardRepository
    private var nextCursor: String?
    private var loadedKey: QueryKey?
    private let calendar: Calendar

    init(repository: any AdGuardRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
        self.isDemo = repository.isDemo
    }

    var queryKey: QueryKey {
        QueryKey(search: searchText.trimmingCharacters(in: .whitespacesAndNewlines), filter: filter)
    }

    var hasMore: Bool { nextCursor != nil }

    /// Narrows the log to a domain or client address via the server-side search.
    func search(for term: String) {
        searchText = term
    }

    /// Loads the first page only if search or filter changed since the last
    /// successful load, so returning from a detail view keeps the list as is.
    func loadIfNeeded() async {
        guard loadedKey != queryKey else { return }
        await reload(debounced: true)
    }

    /// Reloads the first page. Typing is debounced; the calling task is
    /// cancelled by SwiftUI when the query changes again.
    func reload(debounced: Bool = false) async {
        if debounced, !queryKey.search.isEmpty {
            do { try await Task.sleep(for: Self.searchDebounce) } catch { return }
        }
        let key = queryKey
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await repository.fetchQueryLog(QueryLogQuery(search: key.search, filter: key.filter))
            guard !Task.isCancelled, key == queryKey else { return }
            entries = page.entries
            nextCursor = page.nextCursor
            loadedKey = key
            error = nil
            loadMoreError = nil
            hasLoaded = true
        } catch {
            guard error != .cancelled, !Task.isCancelled else { return }
            self.error = error
            hasLoaded = true
        }
    }

    /// Appends the next page; called when the last row becomes visible.
    func loadMore() async {
        guard let cursor = nextCursor, !isLoadingMore else { return }
        let key = queryKey
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let query = QueryLogQuery(search: key.search, filter: key.filter, cursor: cursor)
            let page = try await repository.fetchQueryLog(query)
            guard key == queryKey else { return }
            let knownIDs = Set(entries.map(\.id))
            entries += page.entries.filter { !knownIDs.contains($0.id) }
            nextCursor = page.nextCursor
            loadMoreError = nil
        } catch {
            guard error != .cancelled else { return }
            loadMoreError = error
        }
    }

    func makeRuleModel(for entry: QueryLogEntry) -> DomainRuleModel {
        DomainRuleModel(domain: entry.domain, repository: repository, prefersAllow: entry.outcome.isBlocked)
    }

    /// Loads filter list names once for the detail view. Failure is surfaced
    /// via `catalogError`; the detail view then falls back to list IDs.
    func loadCatalogIfNeeded() async {
        guard catalog == nil else { return }
        do {
            catalog = try await repository.fetchFilterLists()
            catalogError = nil
        } catch {
            guard error != .cancelled else { return }
            catalogError = error
        }
    }
}
