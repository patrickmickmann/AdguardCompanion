import Foundation
import Synchronization
import Testing
@testable import AdguardCompanion

struct FilterListMappingTests {
    @Test func mapsBothKindsAndDates() throws {
        let json = Data("""
        {"enabled":true,"interval":12,
         "filters":[{"id":1,"name":"AdGuard DNS filter","url":"https://a.test/1.txt","enabled":true,
                     "rules_count":5912,"last_updated":"2026-11-20T12:18:57+01:00"}],
         "whitelist_filters":[{"id":2,"name":"","url":"https://a.test/2.txt","enabled":false,
                               "rules_count":3,"last_updated":"2026-11-20T12:18:57.123+01:00"}],
         "user_rules":[]}
        """.utf8)
        let settings = FilterListMapper.map(try JSONDecoder.adGuard.decode(FilterStatusDTO.self, from: json))
        #expect(settings.isFilteringEnabled)
        #expect(settings.updateIntervalHours == 12)
        #expect(settings.lists(of: .blocklist).first?.ruleCount == 5912)
        let allow = try #require(settings.lists(of: .allowlist).first)
        #expect(allow.name == "https://a.test/2.txt")
        #expect(allow.lastUpdated != nil)
        #expect(settings.lists(of: .blocklist).first?.lastUpdated != nil)
    }

    @Test(arguments: [
        ("https://a.test/list.txt", true), ("http://a.test", true), ("/opt/lists/local.txt", true),
        ("ftp://a.test/x", false), ("a.test/list.txt", false), ("https://", false), ("/", false),
        ("https://a.test/a b", false),
    ])
    func validatesSources(input: String, isValid: Bool) {
        #expect((FilterListInput.normalizedSource(input) != nil) == isValid)
    }

    @Test func reportsMissingNameAndDuplicates() {
        let existing = FilterListSettings(isFilteringEnabled: true, updateIntervalHours: 24, lists: [
            FilterList(id: 1, name: "A", url: "https://a.test/1.txt", kind: .blocklist, isEnabled: true,
                       ruleCount: 1, lastUpdated: nil),
        ])
        #expect(FilterListInput.problem(name: " ", source: "https://b.test", kind: .blocklist, existing: existing)
                == .missingName)
        #expect(FilterListInput.problem(name: "A", source: "https://a.test/1.txt", kind: .blocklist,
                                        existing: existing) == .duplicate)
        // The same URL may exist once per kind.
        #expect(FilterListInput.problem(name: "A", source: "https://a.test/1.txt", kind: .allowlist,
                                        existing: existing) == nil)
    }
}

@MainActor
struct FilterListModelTests {
    @Test func togglesAndConfirmsList() async throws {
        let repository = StubRepository()
        let model = FilterListsModel(repository: repository)
        await model.load()
        let list = try #require(model.settings?.lists.first)
        await model.apply(.setEnabled(list, false))
        #expect(model.settings?.lists.first?.isEnabled == false)
        #expect(model.confirmedChanges == 1)
    }

    @Test func addAndRemoveRoundTrip() async throws {
        let model = FilterListsModel(repository: StubRepository())
        await model.load()
        #expect(await model.apply(.add(name: "Neu", url: "https://b.test/x.txt", kind: .allowlist)))
        let added = try #require(model.settings?.list(withURL: "https://b.test/x.txt", kind: .allowlist))
        #expect(await model.apply(.remove(added)))
        #expect(model.settings?.list(withURL: "https://b.test/x.txt", kind: .allowlist) == nil)
    }

    @Test func invalidAddIsRejectedWithoutRequest() async {
        let repository = StubRepository()
        let model = FilterListsModel(repository: repository)
        await model.load()
        #expect(!(await model.apply(.add(name: "X", url: "ftp://x", kind: .blocklist))))
        #expect(model.actionError == .invalidInput)
        #expect(repository.filterListChanges.isEmpty)
    }

    @Test func unconfirmedToggleFallsBackToServerValue() async throws {
        let repository = StubRepository()
        repository.ignoresRuleChanges = true
        let model = FilterListsModel(repository: repository)
        await model.load()
        let list = try #require(model.settings?.lists.first)
        await model.apply(.setEnabled(list, false))
        #expect(model.actionError == .changeNotConfirmed)
        #expect(model.isOn(list))
    }

    @Test func refreshSumsBothKinds() async {
        let model = FilterListsModel(repository: StubRepository())
        await model.load()
        await model.refreshLists()
        #expect(model.refreshedCount == 3)
    }
}

struct FilterListRequestTests {
    @Test func filteringSwitchKeepsInterval() async throws {
        let host = "filterconfig.test"
        let sent = Mutex<(enabled: Bool?, interval: Int?)>((nil, nil))
        StubURLProtocol.register(host: host) { request in
            #expect(request.url?.path() == "/control/filtering/config")
            let json = try JSONSerialization.jsonObject(with: RequestBody.read(request)) as? [String: Any]
            let values = (json?["enabled"] as? Bool, json?["interval"] as? Int)
            sent.withLock { $0 = values }
            return StubURLProtocol.respond(request, status: 200, body: "")
        }
        let current = FilterListSettings(isFilteringEnabled: true, updateIntervalHours: 72, lists: [])
        try await RequestBody.repository(host: host).updateFilterLists(.setFilteringEnabled(false), current: current)
        #expect(sent.withLock { $0.enabled } == false)
        #expect(sent.withLock { $0.interval } == 72)
    }

    @Test func setURLSendsCompleteData() async throws {
        let host = "seturl.test"
        StubURLProtocol.register(host: host) { request in
            #expect(request.url?.path() == "/control/filtering/set_url")
            let json = try JSONSerialization.jsonObject(with: RequestBody.read(request)) as? [String: Any]
            #expect(json?["url"] as? String == "https://a.test/1.txt")
            #expect(json?["whitelist"] as? Bool == true)
            let data = json?["data"] as? [String: Any]
            #expect(data?["enabled"] as? Bool == false)
            #expect(data?["name"] as? String == "A")
            return StubURLProtocol.respond(request, status: 200, body: "OK")
        }
        let list = FilterList(id: 1, name: "A", url: "https://a.test/1.txt", kind: .allowlist, isEnabled: true,
                              ruleCount: 1, lastUpdated: nil)
        let current = FilterListSettings(isFilteringEnabled: true, updateIntervalHours: 24, lists: [list])
        try await RequestBody.repository(host: host).updateFilterLists(.setEnabled(list, false), current: current)
    }

    @Test func refreshDecodesUpdatedCount() async throws {
        let host = "refresh.test"
        StubURLProtocol.register(host: host) { request in
            #expect(request.url?.path() == "/control/filtering/refresh")
            return StubURLProtocol.respond(request, status: 200, body: #"{"updated":4}"#)
        }
        #expect(try await RequestBody.repository(host: host).refreshFilterLists(.blocklist) == 4)
    }
}

/// Helpers for inspecting requests captured by `StubURLProtocol`.
enum RequestBody {
    static func repository(host: String) throws -> LiveAdGuardRepository {
        LiveAdGuardRepository(client: AdGuardAPIClient(
            baseURL: try #require(URL(string: "https://\(host)")),
            credentials: ServerCredentials(username: "u", password: "p"),
            session: StubURLProtocol.makeSession()
        ))
    }

    static func read(_ request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

struct LongOperationTimeoutTests {
    @Test func filterDownloadsUseLongTimeout() async throws {
        let host = "timeout.test"
        StubURLProtocol.register(host: host) { request in
            #expect(request.timeoutInterval == NetworkPolicy.longOperationTimeout)
            return StubURLProtocol.respond(request, status: 200, body: #"{"updated":0}"#)
        }
        _ = try await RequestBody.repository(host: host).refreshFilterLists(.allowlist)
    }

    @Test func ordinaryRequestsKeepDefaultTimeout() {
        #expect(Endpoint.status.timeout == nil)
        #expect(Endpoint.filteringConfig.timeout == nil)
    }
}
