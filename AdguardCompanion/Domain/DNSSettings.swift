import Foundation

/// General DNS settings from `/control/dns_info`, kept as the server's
/// object with typed accessors. Edits are sent as partial updates.
nonisolated struct DNSSettings: Equatable, Sendable {
    enum UpstreamMode: String, CaseIterable, Sendable {
        case loadBalance = "load_balance", parallel, fastestAddress = "fastest_addr"
    }

    let document: JSONObject

    var upstreams: UpstreamSet {
        UpstreamSet(upstreams: document["upstream_dns"]?.strings ?? [],
                    bootstrap: document["bootstrap_dns"]?.strings ?? [],
                    fallback: document["fallback_dns"]?.strings ?? [])
    }

    var upstreamMode: UpstreamMode? { document["upstream_mode"]?.string.flatMap(UpstreamMode.init) }
    var isDNSSECEnabled: Bool { document["dnssec_enabled"]?.bool ?? false }
    var isCacheEnabled: Bool { document["cache_enabled"]?.bool ?? false }
    var isOptimisticCacheEnabled: Bool { document["cache_optimistic"]?.bool ?? false }
    var cacheSize: Int { Int(document["cache_size"]?.number ?? 0) }
    var isIPv6Disabled: Bool { document["disable_ipv6"]?.bool ?? false }
    var rateLimit: Int { Int(document["ratelimit"]?.number ?? 0) }
    var blockingMode: String? { document["blocking_mode"]?.string }

    /// Whether every field in `patch` has the patched value on the server.
    func confirms(_ patch: JSONObject) -> Bool {
        patch.allSatisfy { key, value in
            if let lines = value.array {
                return UpstreamSet.effective(lines.compactMap(\.string)) == UpstreamSet.effective(document[key]?.strings ?? [])
            }
            return document[key] == value
        }
    }
}

/// Upstream, bootstrap and fallback servers, one entry per line.
nonisolated struct UpstreamSet: Equatable, Sendable {
    var upstreams: [String]
    var bootstrap: [String]
    var fallback: [String]

    /// Lines that configure a server: trimmed, non-empty and not a "#" comment.
    static func effective(_ lines: [String]) -> [String] {
        lines.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }

    static func lines(from text: String) -> [String] {
        text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

/// Applies DNS setting changes and confirms them by reading them back.
nonisolated struct DNSSettingsUpdater: Sendable {
    let repository: any AdGuardRepository

    func apply(_ patch: JSONObject) async throws(APIError) -> DNSSettings {
        try await repository.updateDNSSettings(patch)
        let settings = try await repository.fetchDNSSettings()
        guard settings.confirms(patch) else { throw .changeNotConfirmed }
        return settings
    }

    /// Patch for a cache switch. Size and switch are always sent together,
    /// because the server derives one from the other when one is missing.
    static func cachePatch(enabled: Bool, current: DNSSettings) -> JSONObject {
        ["cache_enabled": .bool(enabled), "cache_size": .number(Double(current.cacheSize))]
    }
}

/// Encryption status from `/control/tls/status`. Shown read only: changing
/// certificates from a phone could lock the user out of the server.
nonisolated struct TLSStatus: Equatable, Sendable {
    let document: JSONObject

    var isEnabled: Bool { document["enabled"]?.bool ?? false }
    var serverName: String? { document["server_name"]?.string.flatMap { $0.isEmpty ? nil : $0 } }
    var forcesHTTPS: Bool { document["force_https"]?.bool ?? false }
    var httpsPort: Int? { port("port_https") }
    var dnsOverTLSPort: Int? { port("port_dns_over_tls") }
    var dnsOverQUICPort: Int? { port("port_dns_over_quic") }
    var isCertificateValid: Bool { document["valid_cert"]?.bool ?? false }
    var subject: String? { document["subject"]?.string.flatMap { $0.isEmpty ? nil : $0 } }
    var issuer: String? { document["issuer"]?.string.flatMap { $0.isEmpty ? nil : $0 } }
    var expiresAt: Date? { document["not_after"]?.string.flatMap(FilterListMapper.date(from:)) }
    var dnsNames: [String] { document["dns_names"]?.strings ?? [] }

    private func port(_ key: String) -> Int? {
        document[key]?.number.map(Int.init).flatMap { $0 > 0 ? $0 : nil }
    }
}
