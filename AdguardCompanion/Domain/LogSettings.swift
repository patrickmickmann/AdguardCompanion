import Foundation

/// The query log and the statistics share one configuration shape.
nonisolated enum LogKind: Sendable, Hashable {
    case queryLog, statistics

    /// Retention periods offered by the AdGuard Home web interface.
    var retentionOptions: [Duration] {
        let day = Duration.seconds(86_400)
        switch self {
        case .queryLog: return [.seconds(21_600), day, day * 7, day * 30, day * 90]
        case .statistics: return [day, day * 7, day * 30, day * 90]
        }
    }
}

/// Configuration of the query log or the statistics. Keeps the server's
/// complete object, because the update endpoint replaces it as a whole.
nonisolated struct LogSettings: Equatable, Sendable {
    let kind: LogKind
    private(set) var document: JSONObject

    init(kind: LogKind, document: JSONObject) {
        self.kind = kind
        self.document = document
    }

    var isEnabled: Bool {
        get { document["enabled"]?.bool ?? false }
        set { document["enabled"] = .bool(newValue) }
    }

    /// Retention period; sent in milliseconds.
    var retention: Duration {
        get { .milliseconds(Int64(document["interval"]?.number ?? 0)) }
        set { document["interval"] = .number(newValue.milliseconds) }
    }

    /// Only reported for the query log.
    var anonymizesClientIP: Bool? {
        get { document["anonymize_client_ip"]?.bool }
        set { document["anonymize_client_ip"] = newValue.map(JSONValue.bool) }
    }

    var ignoredDomains: [String] {
        get { document["ignored"]?.strings ?? [] }
        set { document["ignored"] = .array(newValue.map(JSONValue.string)) }
    }

    /// Whether the ignore list is applied; `nil` on servers without this switch.
    var isIgnoreListEnabled: Bool? {
        get { document["ignored_enabled"]?.bool }
        set { document["ignored_enabled"] = newValue.map(JSONValue.bool) }
    }

    /// Offered retention periods, including a custom value set elsewhere.
    var retentionChoices: [Duration] {
        let options = kind.retentionOptions
        return options.contains(retention) || retention == .zero ? options : (options + [retention]).sorted()
    }
}

/// Saves log settings and confirms them by reading them back.
nonisolated struct LogSettingsUpdater: Sendable {
    let repository: any AdGuardRepository

    func save(_ settings: LogSettings) async throws(APIError) -> LogSettings {
        try await repository.updateLogSettings(settings)
        let confirmed = try await repository.fetchLogSettings(settings.kind)
        guard confirmed.isEnabled == settings.isEnabled, confirmed.retention == settings.retention,
              confirmed.anonymizesClientIP == settings.anonymizesClientIP,
              Set(confirmed.ignoredDomains) == Set(settings.ignoredDomains),
              confirmed.isIgnoreListEnabled == settings.isIgnoreListEnabled else { throw .changeNotConfirmed }
        return confirmed
    }
}
