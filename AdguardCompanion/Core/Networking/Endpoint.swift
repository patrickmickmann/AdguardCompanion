import Foundation

/// A documented AdGuard Home API endpoint, relative to the server base URL.
/// Source: AdGuardHome/openapi/openapi.yaml (`servers: /control`).
nonisolated struct Endpoint: Sendable, Equatable {
    let path: String
    var queryItems: [URLQueryItem] = []
    /// Overrides the idle timeout for operations that answer only after
    /// downloading filter lists.
    var timeout: TimeInterval?

    /// `GET /control/status` – server status and general settings.
    static let status = Endpoint(path: "control/status")
    /// `GET /control/stats` – statistics for the configured statistics interval.
    static let stats = Endpoint(path: "control/stats")
    /// `GET /control/filtering/status` – filter lists and filtering settings.
    static let filteringStatus = Endpoint(path: "control/filtering/status")
    /// `POST /control/filtering/set_rules` – replaces all user-defined rules.
    static let setRules = Endpoint(path: "control/filtering/set_rules")
    /// `POST /control/protection` – enables, pauses or disables protection.
    static let protection = Endpoint(path: "control/protection")
    /// `GET /control/safebrowsing/status`, `POST …/enable`, `POST …/disable`.
    static let safeBrowsingStatus = Endpoint(path: "control/safebrowsing/status")
    static let safeBrowsingEnable = Endpoint(path: "control/safebrowsing/enable")
    static let safeBrowsingDisable = Endpoint(path: "control/safebrowsing/disable")
    /// `GET /control/parental/status`, `POST …/enable`, `POST …/disable`.
    static let parentalStatus = Endpoint(path: "control/parental/status")
    static let parentalEnable = Endpoint(path: "control/parental/enable")
    static let parentalDisable = Endpoint(path: "control/parental/disable")
    /// `GET /control/safesearch/status` and `PUT /control/safesearch/settings`.
    static let safeSearchStatus = Endpoint(path: "control/safesearch/status")
    static let safeSearchSettings = Endpoint(path: "control/safesearch/settings")
    /// Filter list management under `/control/filtering/…` (all `POST`).
    static let filteringConfig = Endpoint(path: "control/filtering/config")
    static let addFilterURL = Endpoint(path: "control/filtering/add_url", timeout: NetworkPolicy.longOperationTimeout)
    static let removeFilterURL = Endpoint(path: "control/filtering/remove_url")
    static let setFilterURL = Endpoint(path: "control/filtering/set_url", timeout: NetworkPolicy.longOperationTimeout)
    static let refreshFilters = Endpoint(path: "control/filtering/refresh", timeout: NetworkPolicy.longOperationTimeout)
    /// DNS rewrites: `GET list`, `POST add`/`delete`, `PUT update`,
    /// `GET settings`, `PUT settings/update`.
    static let rewriteList = Endpoint(path: "control/rewrite/list")
    static let rewriteAdd = Endpoint(path: "control/rewrite/add")
    static let rewriteDelete = Endpoint(path: "control/rewrite/delete")
    static let rewriteUpdate = Endpoint(path: "control/rewrite/update")
    static let rewriteSettings = Endpoint(path: "control/rewrite/settings")
    static let rewriteSettingsUpdate = Endpoint(path: "control/rewrite/settings/update")
    /// `GET /control/blocked_services/get` and `PUT …/update` (ids and schedule).
    static let blockedServicesGet = Endpoint(path: "control/blocked_services/get")
    static let blockedServicesUpdate = Endpoint(path: "control/blocked_services/update")
    /// Query log and statistics configuration (`GET …/config`, `PUT …/config/update`)
    /// and their destructive resets (`POST`).
    static let queryLogConfig = Endpoint(path: "control/querylog/config")
    static let queryLogConfigUpdate = Endpoint(path: "control/querylog/config/update")
    static let queryLogClear = Endpoint(path: "control/querylog_clear")
    static let statsConfig = Endpoint(path: "control/stats/config")
    static let statsConfigUpdate = Endpoint(path: "control/stats/config/update")
    static let statsReset = Endpoint(path: "control/stats_reset")
    /// `GET /control/dns_info`, `POST /control/dns_config` (partial: omitted
    /// fields stay unchanged) and `POST /control/test_upstream_dns`.
    static let dnsInfo = Endpoint(path: "control/dns_info")
    static let dnsConfig = Endpoint(path: "control/dns_config")
    static let testUpstreams = Endpoint(path: "control/test_upstream_dns", timeout: NetworkPolicy.longOperationTimeout)
    /// `GET /control/tls/status` – read only in this app.
    static let tlsStatus = Endpoint(path: "control/tls/status")
    /// `GET /control/clients` – configured and automatically discovered clients.
    static let clients = Endpoint(path: "control/clients")
    /// `GET /control/blocked_services/all` – services available for blocking.
    static let blockedServices = Endpoint(path: "control/blocked_services/all")

    /// `GET /control/querylog` with documented parameters only:
    /// `limit`, `older_than`, `search` and repeated `reason`.
    static func queryLog(_ query: QueryLogQuery) -> Endpoint {
        var items = [URLQueryItem(name: "limit", value: String(query.limit))]
        if let cursor = query.cursor {
            items.append(URLQueryItem(name: "older_than", value: cursor))
        }
        let search = query.trimmedSearch
        if !search.isEmpty {
            items.append(URLQueryItem(name: "search", value: search))
        }
        items += query.filter.reasons.map { URLQueryItem(name: "reason", value: $0) }
        return Endpoint(path: "control/querylog", queryItems: items)
    }

    func url(relativeTo baseURL: URL) -> URL {
        let url = baseURL.appending(path: path)
        guard !queryItems.isEmpty,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        components.queryItems = queryItems
        // URLComponents leaves "+" unescaped, but servers decode it as a space.
        // Timestamps like "…+01:00" must therefore be escaped explicitly.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        return components.url ?? url
    }
}
