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
    func fetchProtectionSettings() async throws(APIError) -> ProtectionSettings
    func updateProtection(_ change: ProtectionChange) async throws(APIError)
    func fetchFilterListSettings() async throws(APIError) -> FilterListSettings
    /// `current` provides values the API requires but the change keeps, such as the update interval.
    func updateFilterLists(_ change: FilterListChange, current: FilterListSettings) async throws(APIError)
    /// Returns how many lists were updated.
    func refreshFilterLists(_ kind: FilterList.Kind) async throws(APIError) -> Int
    func fetchRewrites() async throws(APIError) -> DNSRewriteSettings
    func updateRewrites(_ change: DNSRewriteChange) async throws(APIError)
    func fetchBlockedServices() async throws(APIError) -> BlockedServices
    /// Replaces the set of globally blocked services; the schedule is kept.
    func setBlockedServices(_ ids: Set<String>, keeping current: BlockedServices) async throws(APIError)
    func fetchLogSettings(_ kind: LogKind) async throws(APIError) -> LogSettings
    /// Sends the complete configuration object back with the edited fields.
    func updateLogSettings(_ settings: LogSettings) async throws(APIError)
    /// Deletes the query log or resets the statistics.
    func clearLogData(_ kind: LogKind) async throws(APIError)
    func fetchDNSSettings() async throws(APIError) -> DNSSettings
    /// Sends only the given fields; the server leaves all others unchanged.
    func updateDNSSettings(_ patch: JSONObject) async throws(APIError)
    /// Asks AdGuard Home to resolve a test name via each upstream.
    /// Returns the server's result per upstream ("OK" or an error text).
    func testUpstreams(_ upstreams: UpstreamSet) async throws(APIError) -> [String: String]
    func fetchTLSStatus() async throws(APIError) -> TLSStatus
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
        try await client.write(.setRules, body: SetRulesRequestDTO(rules: rules))
    }
}
