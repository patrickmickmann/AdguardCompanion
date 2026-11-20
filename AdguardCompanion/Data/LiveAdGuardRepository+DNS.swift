import Foundation

extension LiveAdGuardRepository {
    func fetchDNSSettings() async throws(APIError) -> DNSSettings {
        DNSSettings(document: try await client.getDocument(.dnsInfo))
    }

    func updateDNSSettings(_ patch: JSONObject) async throws(APIError) {
        try await client.write(.dnsConfig, body: patch)
    }

    func testUpstreams(_ upstreams: UpstreamSet) async throws(APIError) -> [String: String] {
        // `components/schemas/UpstreamsConfig`; private upstreams are not tested here.
        let body: JSONObject = [
            "upstream_dns": .array(UpstreamSet.effective(upstreams.upstreams).map(JSONValue.string)),
            "bootstrap_dns": .array(UpstreamSet.effective(upstreams.bootstrap).map(JSONValue.string)),
            "fallback_dns": .array(UpstreamSet.effective(upstreams.fallback).map(JSONValue.string)),
            "private_upstream": .array([]),
        ]
        let response = try await client.write(.testUpstreams, body: body, returning: JSONObject.self)
        return response.compactMapValues(\.string)
    }

    func fetchTLSStatus() async throws(APIError) -> TLSStatus {
        TLSStatus(document: try await client.getDocument(.tlsStatus))
    }
}
