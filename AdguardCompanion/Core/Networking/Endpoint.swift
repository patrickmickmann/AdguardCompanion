import Foundation

/// A documented AdGuard Home API endpoint, relative to the server base URL.
/// Source: AdGuardHome/openapi/openapi.yaml (`servers: /control`).
nonisolated struct Endpoint: Sendable, Equatable {
    let path: String
    var queryItems: [URLQueryItem] = []

    /// `GET /control/status` – server status and general settings.
    static let status = Endpoint(path: "control/status")
    /// `GET /control/stats` – statistics for the configured statistics interval.
    static let stats = Endpoint(path: "control/stats")
    /// `GET /control/filtering/status` – filter lists and filtering settings.
    static let filteringStatus = Endpoint(path: "control/filtering/status")
    /// `POST /control/filtering/set_rules` – replaces all user-defined rules.
    static let setRules = Endpoint(path: "control/filtering/set_rules")
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
