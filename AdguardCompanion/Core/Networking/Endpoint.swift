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

    func url(relativeTo baseURL: URL) -> URL {
        let url = baseURL.appending(path: path)
        guard !queryItems.isEmpty else { return url }
        return url.appending(queryItems: queryItems)
    }
}
