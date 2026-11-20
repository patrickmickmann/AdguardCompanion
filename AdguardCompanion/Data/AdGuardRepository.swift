import Foundation

/// Read access to an AdGuard Home instance, independent of whether the data
/// comes from a real server or from the clearly labeled demo source.
protocol AdGuardRepository: Sendable {
    /// `true` when data is sample data and not from a real server.
    var isDemo: Bool { get }

    func fetchServerStatus() async throws(APIError) -> ServerStatus
    func fetchStatistics() async throws(APIError) -> DashboardStatistics
    func fetchQueryLog(_ query: QueryLogQuery) async throws(APIError) -> QueryLogPage
    func fetchFilterLists() async throws(APIError) -> FilterListCatalog
    func fetchClients() async throws(APIError) -> [NetworkClient]
    /// Blocked service names by ID, e.g. "youtube" → "YouTube".
    func fetchBlockedServiceNames() async throws(APIError) -> [String: String]
    /// User-defined filtering rules, one rule or comment per line.
    func fetchUserRules() async throws(APIError) -> [String]
    /// Replaces all user-defined filtering rules.
    func replaceUserRules(_ rules: [String]) async throws(APIError)
}

/// Production repository backed by the AdGuard Home REST API.
struct LiveAdGuardRepository: AdGuardRepository {
    let client: AdGuardAPIClient
    var calendar: Calendar = .current

    var isDemo: Bool { false }

    func fetchServerStatus() async throws(APIError) -> ServerStatus {
        let dto: ServerStatusDTO = try await client.get(.status)
        return ServerStatusMapper.map(dto, now: .now)
    }

    func fetchStatistics() async throws(APIError) -> DashboardStatistics {
        let dto: StatsDTO = try await client.get(.stats)
        return StatisticsMapper.map(dto, now: .now, calendar: calendar)
    }

    func fetchQueryLog(_ query: QueryLogQuery) async throws(APIError) -> QueryLogPage {
        let dto: QueryLogDTO = try await client.get(.queryLog(query))
        return QueryLogMapper.map(dto, requestedLimit: query.limit)
    }

    func fetchFilterLists() async throws(APIError) -> FilterListCatalog {
        let dto: FilterStatusDTO = try await client.get(.filteringStatus)
        return FilterListCatalog(dto)
    }

    func fetchClients() async throws(APIError) -> [NetworkClient] {
        async let clients: ClientsDTO = client.get(.clients)
        async let stats: StatsDTO = client.get(.stats)
        do {
            let topClients = StatisticsMapper.ranked(try await stats.topClients)
            return ClientsMapper.map(try await clients, topClients: topClients)
        } catch {
            // `async let` erases the typed error; both calls only throw APIError.
            throw APIError(error)
        }
    }

    func fetchBlockedServiceNames() async throws(APIError) -> [String: String] {
        let dto: BlockedServicesAllDTO = try await client.get(.blockedServices)
        var names: [String: String] = [:]
        for service in dto.blockedServices ?? [] {
            guard let id = service.id, let name = service.name else { continue }
            names[id] = name
        }
        return names
    }

    func fetchUserRules() async throws(APIError) -> [String] {
        let dto: FilterStatusDTO = try await client.get(.filteringStatus)
        return dto.userRules ?? []
    }

    func replaceUserRules(_ rules: [String]) async throws(APIError) {
        try await client.post(.setRules, body: SetRulesRequestDTO(rules: rules))
    }
}
