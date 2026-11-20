import Foundation

/// DEMO DATA ONLY. Administration features backed by in-memory demo state.
extension DemoAdGuardRepository {
    func fetchRewrites() async throws(APIError) -> DNSRewriteSettings { rewrites.current() }

    func updateRewrites(_ change: DNSRewriteChange) async throws(APIError) { rewrites.apply(change) }

    func fetchBlockedServices() async throws(APIError) -> BlockedServices { blockedServices.current() }

    func setBlockedServices(_ ids: Set<String>, keeping current: BlockedServices) async throws(APIError) {
        blockedServices.set(ids)
    }

    func fetchLogSettings(_ kind: LogKind) async throws(APIError) -> LogSettings { logSettings.current(kind) }

    func updateLogSettings(_ settings: LogSettings) async throws(APIError) { logSettings.save(settings) }

    /// Demo data is generated, so there is nothing to delete.
    func clearLogData(_ kind: LogKind) async throws(APIError) {}

    func fetchDNSSettings() async throws(APIError) -> DNSSettings { dnsSettings.current() }

    func updateDNSSettings(_ patch: JSONObject) async throws(APIError) { dnsSettings.apply(patch) }

    func testUpstreams(_ upstreams: UpstreamSet) async throws(APIError) -> [String: String] {
        Dictionary(uniqueKeysWithValues: UpstreamSet.effective(upstreams.upstreams).map { ($0, "OK") })
    }

    func fetchTLSStatus() async throws(APIError) -> TLSStatus { DemoDNSSettings.tls }
}
