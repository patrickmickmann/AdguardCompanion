import Foundation

extension LiveAdGuardRepository {
    func fetchLogSettings(_ kind: LogKind) async throws(APIError) -> LogSettings {
        LogSettings(kind: kind, document: try await client.getDocument(Self.endpoints(kind).config))
    }

    func updateLogSettings(_ settings: LogSettings) async throws(APIError) {
        try await client.write(Self.endpoints(settings.kind).update, method: .put, body: settings.document)
    }

    func clearLogData(_ kind: LogKind) async throws(APIError) {
        try await client.write(Self.endpoints(kind).clear)
    }

    private static func endpoints(_ kind: LogKind) -> (config: Endpoint, update: Endpoint, clear: Endpoint) {
        switch kind {
        case .queryLog: (.queryLogConfig, .queryLogConfigUpdate, .queryLogClear)
        case .statistics: (.statsConfig, .statsConfigUpdate, .statsReset)
        }
    }
}
