import Foundation

/// DEMO DATA ONLY. Generates deterministic sample data so the app can be
/// explored without a server. Every screen showing this data is labeled
/// "Demo" and it is never mixed with live data.
struct DemoAdGuardRepository: AdGuardRepository {
    var calendar: Calendar = .current
    /// In-memory user rules so rule changes can be tried out in the demo.
    private let userRules = DemoUserRules()
    /// In-memory protection switches for the demo.
    private let protection = DemoProtection()
    private let filterLists = DemoFilterLists()

    var isDemo: Bool { true }

    func fetchServerStatus() async throws(APIError) -> ServerStatus {
        let dto = ServerStatusDTO(
            version: "v0.107.57",
            running: true,
            protectionEnabled: true,
            protectionDisabledDuration: 0,
            dnsAddresses: ["192.168.1.2"],
            dnsPort: 53,
            httpPort: 3000,
            startTime: Date.now.addingTimeInterval(-12 * 86_400).timeIntervalSince1970 * 1000
        )
        let status = ServerStatusMapper.map(dto, now: .now)
        return ServerStatus(
            version: status.version, isDNSRunning: status.isDNSRunning, filtering: protection.current().protection,
            dnsAddresses: status.dnsAddresses, dnsPort: status.dnsPort, startedAt: status.startedAt
        )
    }

    func fetchStatistics() async throws(APIError) -> DashboardStatistics {
        StatisticsMapper.map(Self.sampleStats(), now: .now, calendar: calendar)
    }

    func fetchQueryLog(_ query: QueryLogQuery) async throws(APIError) -> QueryLogPage {
        DemoQueryLog.page(for: query, now: .now)
    }

    func fetchFilterLists() async throws(APIError) -> FilterListCatalog {
        DemoQueryLog.catalog
    }

    func fetchClients() async throws(APIError) -> [NetworkClient] {
        let top = StatisticsMapper.ranked(Self.sampleStats().topClients)
        return ClientsMapper.map(DemoClients.clients, topClients: top)
    }

    func fetchBlockedServiceNames() async throws(APIError) -> [String: String] {
        DemoClients.serviceNames
    }

    func fetchUserRules() async throws(APIError) -> [String] {
        userRules.current()
    }

    func replaceUserRules(_ rules: [String]) async throws(APIError) {
        userRules.replace(with: rules)
    }

    func fetchProtectionSettings() async throws(APIError) -> ProtectionSettings {
        protection.current()
    }

    func updateProtection(_ change: ProtectionChange) async throws(APIError) {
        protection.apply(change)
    }

    func fetchFilterListSettings() async throws(APIError) -> FilterListSettings {
        filterLists.current()
    }

    func updateFilterLists(_ change: FilterListChange, current: FilterListSettings) async throws(APIError) {
        filterLists.apply(change)
    }

    func refreshFilterLists(_ kind: FilterList.Kind) async throws(APIError) -> Int { 0 }

    /// Hourly sample curve with a daytime peak; totals are derived from the series.
    static func sampleStats() -> StatsDTO {
        let hours = 0..<24
        let queries = hours.map { hour in
            let daytime = sin(Double(hour) / 24 * .pi)
            return 4_200 + Int(daytime * 9_800) + (hour % 3) * 650
        }
        let blocked = queries.enumerated().map { index, value in
            value * (28 + index % 7) / 100
        }
        return StatsDTO(
            timeUnits: "hours",
            numDnsQueries: queries.reduce(0, +),
            numBlockedFiltering: blocked.reduce(0, +),
            numReplacedSafebrowsing: 0,
            numReplacedSafesearch: 0,
            numReplacedParental: 0,
            avgProcessingTime: 0.014,
            topQueriedDomains: sample(["www.apple.com": 18_204, "api.github.com": 9_877,
                                       "icloud.com": 7_412, "time.apple.com": 5_903, "wikipedia.org": 3_110]),
            topClients: sample(["192.168.1.12": 12_431, "192.168.1.10": 28_915,
                                "192.168.1.23": 8_742, "192.168.1.30": 6_119, "192.168.1.45": 3_507]),
            topBlockedDomains: sample(["doubleclick.net": 6_402, "ads.google.com": 4_918,
                                       "telemetry.microsoft.com": 3_377, "app-measurement.com": 2_051,
                                       "tracking.example.net": 1_204]),
            dnsQueries: queries,
            blockedFiltering: blocked,
            replacedSafebrowsing: nil,
            replacedParental: nil
        )
    }

    private static func sample(_ values: KeyValuePairs<String, Double>) -> [[String: Double]] {
        values.sorted { $0.value > $1.value }.map { [$0.key: $0.value] }
    }
}
