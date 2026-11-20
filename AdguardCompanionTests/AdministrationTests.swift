import Foundation
import Synchronization
import Testing
@testable import AdguardCompanion

@MainActor
struct UserRulesTests {
    @Test func validatesRules() {
        #expect(UserRulesUpdater.normalizedRule("  ||a.com^ ") == "||a.com^")
        #expect(UserRulesUpdater.normalizedRule("   ") == nil)
        #expect(UserRulesUpdater.normalizedRule("||a.com^\n||b.com^") == nil)
        #expect(UserRulesUpdater.isComment("! note") && UserRulesUpdater.isComment("# note"))
    }

    @Test func addsAndRemovesKeepingOtherRules() async throws {
        let repository = StubRepository()
        repository.userRules = ["! keep", "||b.com^"]
        let updater = UserRulesUpdater(repository: repository)
        #expect(try await updater.add("||a.com^") == ["! keep", "||b.com^", "||a.com^"])
        #expect(try await updater.remove("||b.com^") == ["! keep", "||a.com^"])
    }

    @Test func modelReportsUnconfirmedAdd() async {
        let repository = StubRepository()
        repository.ignoresRuleChanges = true
        let model = UserRulesModel(repository: repository)
        await model.load()
        #expect(!(await model.add("||x.com^")))
        #expect(model.actionError == .changeNotConfirmed)
    }
}

@MainActor
struct DNSRewriteTests {
    @Test(arguments: [
        ("nas.home.arpa", "192.168.1.2", true), ("*.lab.test", "fd00::1", true), ("a.test", "b.test", true),
        ("a.test", "AAAA", true), ("a test", "1.2.3.4", false), ("a.test", "999.1.1.1", false), ("", "1.2.3.4", false),
    ])
    func validatesInput(domain: String, answer: String, isValid: Bool) {
        #expect((DNSRewriteInput.rewrite(domain: domain, answer: answer) != nil) == isValid)
    }

    @Test func addUpdateRemoveRoundTrip() async throws {
        let model = DNSRewritesModel(repository: StubRepository())
        await model.load()
        let new = DNSRewrite(domain: "x.test", answer: "1.2.3.4", isEnabled: true)
        #expect(await model.apply(.add(new)))
        let changed = DNSRewrite(domain: "x.test", answer: "5.6.7.8", isEnabled: true)
        #expect(await model.apply(.update(new, to: changed)))
        #expect(model.settings?.entry(matching: new) == nil)
        #expect(await model.apply(.remove(changed)))
        #expect(model.settings?.entry(matching: changed) == nil)
    }

    @Test func rejectsDuplicateAdd() async throws {
        let model = DNSRewritesModel(repository: StubRepository())
        await model.load()
        let existing = try #require(model.settings?.rewrites.first)
        #expect(!(await model.apply(.add(existing))))
        #expect(model.actionError == .invalidInput)
    }
}

@MainActor
struct BlockedServicesTests {
    @Test func groupsAndSearches() {
        let services = DemoBlockedServices().current()
        let groups = services.groups(matching: "")
        #expect(groups.map(\.id).contains("streaming"))
        #expect(services.groups(matching: "tube").flatMap(\.services).map(\.id) == ["youtube"])
        #expect(BlockedServiceGroup.title("social_network") == "Soziale Netzwerke")
        #expect(BlockedServiceGroup.title("new_group") == "New Group")
    }

    @Test func togglesService() async throws {
        let model = BlockedServicesModel(repository: StubRepository())
        await model.load()
        let youtube = try #require(model.services?.catalog.first { $0.id == "youtube" })
        await model.setBlocked(youtube, true)
        #expect(model.isBlocked(youtube))
        #expect(model.confirmedChanges == 1)
    }

    @Test func updateKeepsScheduleAndSendsIDs() async throws {
        let host = "services.test"
        let sent = Mutex<(ids: [String], zone: String?)>(([], nil))
        StubURLProtocol.register(host: host) { request in
            #expect(request.httpMethod == "PUT")
            let json = try JSONDecoder().decode(JSONObject.self, from: RequestBody.read(request))
            let values = (json["ids"]?.strings ?? [], json["schedule"]?.object?["time_zone"]?.string)
            sent.withLock { $0 = values }
            return StubURLProtocol.respond(request, status: 200, body: "")
        }
        let current = BlockedServices(catalog: [], blockedIDs: [], schedule: .object(["time_zone": .string("Europe/Berlin")]))
        try await RequestBody.repository(host: host).setBlockedServices(["tiktok", "a"], keeping: current)
        #expect(sent.withLock { $0.ids } == ["a", "tiktok"])
        #expect(sent.withLock { $0.zone } == "Europe/Berlin")
    }
}

@MainActor
struct LogSettingsTests {
    @Test func accessorsAndCustomRetention() {
        var settings = LogSettings(kind: .queryLog, document: ["interval": .number(2 * 86_400_000), "extra": .bool(true)])
        #expect(settings.retention == .seconds(2 * 86_400))
        #expect(settings.retentionChoices.contains(.seconds(2 * 86_400)))
        settings.isEnabled = true
        settings.ignoredDomains = ["a.test"]
        #expect(settings.document["extra"] == .bool(true))
        #expect(settings.document["ignored"] == .array([.string("a.test")]))
        #expect(LogKindTexts.retention(.seconds(21_600)) == "6 Stunden")
        #expect(LogKindTexts.retention(.seconds(7 * 86_400)) == "7 Tage")
    }

    @Test func modelSavesAndAddsIgnoredDomain() async {
        let model = LogSettingsModel(kind: .queryLog, repository: StubRepository())
        await model.load()
        #expect(await model.update { $0.anonymizesClientIP = true })
        model.newIgnoredDomain = "*.Tracker.test"
        await model.addIgnoredDomain()
        #expect(model.settings?.ignoredDomains.contains("*.tracker.test") == true)
        #expect(model.newIgnoredDomain.isEmpty)
    }

    @Test func updateSendsWholeDocumentWithOriginalKeys() async throws {
        let host = "logconfig.test"
        let keys = Mutex<Set<String>>([])
        StubURLProtocol.register(host: host) { request in
            #expect(request.url?.path() == "/control/querylog/config/update")
            let json = try JSONDecoder().decode(JSONObject.self, from: RequestBody.read(request))
            keys.withLock { $0 = Set(json.keys) }
            return StubURLProtocol.respond(request, status: 200, body: "")
        }
        let settings = LogSettings(kind: .queryLog, document: [
            "enabled": .bool(true), "interval": .number(86_400_000), "anonymize_client_ip": .bool(false),
            "ignored": .array([]), "ignored_enabled": .bool(true),
        ])
        try await RequestBody.repository(host: host).updateLogSettings(settings)
        #expect(keys.withLock { $0 } == ["enabled", "interval", "anonymize_client_ip", "ignored", "ignored_enabled"])
    }
}

@MainActor
struct DNSSettingsTests {
    @Test func confirmsUpstreamsIgnoringComments() {
        let settings = DNSSettings(document: ["upstream_dns": .array([.string("tls://1.1.1.1")])])
        #expect(settings.confirms(["upstream_dns": .array([.string("# note"), .string(" tls://1.1.1.1 ")])]))
        #expect(!settings.confirms(["dnssec_enabled": .bool(true)]))
    }

    @Test func cachePatchSendsSizeAndSwitch() {
        let settings = DNSSettings(document: ["cache_size": .number(1024)])
        #expect(DNSSettingsUpdater.cachePatch(enabled: false, current: settings)
                == ["cache_enabled": .bool(false), "cache_size": .number(1024)])
    }

    @Test func modelAppliesPatch() async {
        let model = DNSSettingsModel(repository: StubRepository())
        await model.load()
        #expect(await model.apply(["upstream_mode": .string("parallel")]))
        #expect(model.settings?.upstreamMode == .parallel)
    }

    @Test func partialUpdateSendsOnlyPatch() async throws {
        let host = "dnsconfig.test"
        let body = Mutex<JSONObject>([:])
        StubURLProtocol.register(host: host) { request in
            #expect(request.url?.path() == "/control/dns_config")
            let json = try JSONDecoder().decode(JSONObject.self, from: RequestBody.read(request))
            body.withLock { $0 = json }
            return StubURLProtocol.respond(request, status: 200, body: "")
        }
        try await RequestBody.repository(host: host).updateDNSSettings(["dnssec_enabled": .bool(true)])
        #expect(body.withLock { $0 } == ["dnssec_enabled": .bool(true)])
    }

    @Test func upstreamTestSkipsCommentsAndReadsResults() async throws {
        let host = "upstreamtest.test"
        let sent = Mutex<[String]>([])
        StubURLProtocol.register(host: host) { request in
            let json = try JSONDecoder().decode(JSONObject.self, from: RequestBody.read(request))
            sent.withLock { $0 = json["upstream_dns"]?.strings ?? [] }
            return StubURLProtocol.respond(request, status: 200, body: #"{"tls://1.1.1.1":"OK","bad":"no such host"}"#)
        }
        let set = UpstreamSet(upstreams: ["# c", "tls://1.1.1.1", "bad"], bootstrap: [], fallback: [])
        let result = try await RequestBody.repository(host: host).testUpstreams(set)
        #expect(sent.withLock { $0 } == ["tls://1.1.1.1", "bad"])
        #expect(result["bad"] == "no such host")
    }

    @Test func parsesTLSStatus() throws {
        let json = Data(#"{"enabled":true,"server_name":"dns.test","port_https":443,"port_dns_over_tls":0,"valid_cert":true,"not_after":"2027-01-01T00:00:00Z","dns_names":["dns.test"]}"#.utf8)
        let status = TLSStatus(document: try JSONDecoder().decode(JSONObject.self, from: json))
        #expect(status.isEnabled && status.isCertificateValid)
        #expect(status.httpsPort == 443 && status.dnsOverTLSPort == nil)
        #expect(status.expiresAt != nil)
    }
}

struct JSONValueTests {
    @Test func roundTripsNestedValues() throws {
        let json = Data(#"{"a":[1,true,null,"x"],"b":{"c":2.5}}"#.utf8)
        let value = try JSONDecoder().decode(JSONValue.self, from: json)
        let again = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder.adGuard.encode(value))
        #expect(value == again)
        #expect(value.object?["b"]?.object?["c"]?.number == 2.5)
    }
}

struct UserRuleKindTests {
    @Test(arguments: [
        ("||ads.test^", UserRuleKind.block(domain: "ads.test")),
        ("@@||ok.test^$important", .allow(domain: "ok.test")),
        ("! note", .comment),
        ("127.0.0.1 a.test", .other),
        ("||a.test^|b", .other),
    ])
    func recognizesRuleKinds(rule: String, kind: UserRuleKind) {
        #expect(UserRuleKind(rule) == kind)
    }
}
