import Foundation
import Observation

/// Presentation state of the client list. Read-only for now.
@Observable
final class ClientsModel {
    enum SortOrder: String, CaseIterable, Identifiable {
        case activity, name
        var id: Self { self }
    }

    var searchText = ""
    var sortOrder: SortOrder = .activity

    private(set) var clients: [NetworkClient] = []
    private(set) var hasLoaded = false
    private(set) var isLoading = false
    private(set) var error: APIError?
    private(set) var serviceNames: [String: String] = [:]

    let isDemo: Bool
    let repository: any AdGuardRepository

    init(repository: any AdGuardRepository) {
        self.repository = repository
        self.isDemo = repository.isDemo
    }

    var configured: [NetworkClient] { visible.filter(\.isConfigured) }
    var discovered: [NetworkClient] { visible.filter { !$0.isConfigured } }

    /// Locally filtered and sorted; the client list is small.
    private var visible: [NetworkClient] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = term.isEmpty ? clients : clients.filter { client in
            client.name.localizedStandardContains(term)
                || client.identifiers.contains { $0.localizedStandardContains(term) }
        }
        return sortOrder == .name ? ClientsMapper.sortedByName(matching) : ClientsMapper.sorted(matching)
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            clients = try await repository.fetchClients()
            error = nil
        } catch {
            guard error != .cancelled else { return }
            self.error = error
        }
        hasLoaded = true
    }

    /// Most recent query of a client across all its IP addresses, using an
    /// exact query log search with a single entry per address.
    func lastActivity(of client: NetworkClient) async throws(APIError) -> QueryLogEntry? {
        var latest: QueryLogEntry?
        for address in client.ipAddresses {
            let query = QueryLogQuery(search: QueryLogQuery.exactTerm(address), limit: 1)
            guard let entry = try await repository.fetchQueryLog(query).entries.first else { continue }
            if latest.map({ entry.date > $0.date }) ?? true { latest = entry }
        }
        return latest
    }

    /// Loads service names once for the detail view. On failure the
    /// detail view shows the raw service IDs instead.
    func loadServiceNamesIfNeeded() async {
        guard serviceNames.isEmpty else { return }
        do {
            serviceNames = try await repository.fetchBlockedServiceNames()
        } catch {
            // Non-critical: IDs remain readable ("youtube"); no error UI needed.
            return
        }
    }
}
