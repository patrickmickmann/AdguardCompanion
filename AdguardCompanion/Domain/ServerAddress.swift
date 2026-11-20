import Foundation

nonisolated enum ServerAddressError: Error, Equatable {
    case empty
    case invalid
    case unsupportedScheme
}

/// Validates and normalizes the user-entered AdGuard Home address into the
/// base URL the API paths (`control/...`) are appended to.
nonisolated enum ServerAddress {
    static func parse(_ input: String) throws(ServerAddressError) -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .empty }

        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard var components = URLComponents(string: withScheme) else { throw .invalid }

        guard let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            throw .unsupportedScheme
        }
        guard let host = components.host, !host.isEmpty, !host.contains(" ") else { throw .invalid }
        guard components.query == nil, components.fragment == nil, components.user == nil else {
            throw .invalid
        }

        components.scheme = scheme
        components.path = normalizedPath(components.path)
        guard let url = components.url else { throw .invalid }
        return url
    }

    /// `true` if the user typed a scheme such as `http://` themselves.
    static func hasExplicitScheme(_ input: String) -> Bool {
        input.trimmingCharacters(in: .whitespacesAndNewlines).contains("://")
    }

    /// `true` if requests to this URL would be sent unencrypted.
    static func isInsecure(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "http"
    }

    /// Strips trailing slashes and a trailing `/control` the user may have copied.
    private static func normalizedPath(_ path: String) -> String {
        var path = path
        while path.hasSuffix("/") { path.removeLast() }
        if path.lowercased().hasSuffix("/control") { path.removeLast("/control".count) }
        return path
    }
}
