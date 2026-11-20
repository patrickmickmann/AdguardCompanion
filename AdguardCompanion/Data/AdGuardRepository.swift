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
}
