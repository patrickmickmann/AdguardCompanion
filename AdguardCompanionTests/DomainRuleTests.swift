import Foundation
import Testing
@testable import AdguardCompanion

struct CustomDomainRulesTests {
    @Test(arguments: [
        ("Ads.Example.com.", "ads.example.com"), (" tracker.net ", "tracker.net"), ("_dmarc.example.org", "_dmarc.example.org"),
    ])
    func normalizesDomains(input: String, expected: String) {
        #expect(CustomDomainRules.normalizedDomain(input) == expected)
    }

    @Test(arguments: ["", "a b.com", "evil.com^$important", "||x.com", "x.com/path", "..com", ".x.com", "ex\u{e4}mple.de"])
    func rejectsInputThatCouldInjectRuleSyntax(input: String) {
        #expect(CustomDomainRules.normalizedDomain(input) == nil)
    }

    @Test func detectsStateWithAllowWinning() {
        #expect(CustomDomainRules.state(of: "a.com", in: ["||a.com^"]) == .blocked)
        #expect(CustomDomainRules.state(of: "a.com", in: ["||a.com^$important", "@@||a.com^$important"]) == .allowed)
        #expect(CustomDomainRules.state(of: "a.com", in: ["||sub.a.com^", "# a.com"]) == .none)
    }

    @Test func blockReplacesAllowAndKeepsOtherRules() {
        let rules = ["! comment", "@@||a.com^$important", "||b.com^"]
        let result = CustomDomainRules.applying(.block, to: "a.com", in: rules)
        #expect(result == ["! comment", "||b.com^", "||a.com^$important"])
    }

    @Test func wrappableDomainOnlyAddsInvisibleBreaks() {
        let wrapped = DomainDisplayParts.wrappable("a.b.com")
        #expect(wrapped == "a.\u{200B}b.\u{200B}com")
        #expect(wrapped.replacingOccurrences(of: "\u{200B}", with: "") == "a.b.com")
    }

    @Test func removeDropsAllVariantsOnly() {
        let rules = ["||a.com^", "@@||a.com^$important", "||a.com.evil^"]
        #expect(CustomDomainRules.applying(.remove, to: "a.com", in: rules) == ["||a.com.evil^"])
    }
}

@MainActor
struct DomainRuleUpdaterTests {
    @Test func blockReadsFreshRulesWritesAndConfirms() async throws {
        let repository = StubRepository()
        repository.userRules = ["||other.com^"]
        let status = try await DomainRuleUpdater(repository: repository).apply(.block, to: "Ads.Example.com")
        #expect(status == .init(state: .blocked, rule: "||ads.example.com^$important"))
        #expect(repository.replacedRules == [["||other.com^", "||ads.example.com^$important"]])
    }

    @Test func unchangedRulesAreNotWrittenAgain() async throws {
        let repository = StubRepository()
        repository.userRules = ["||a.com^$important"]
        _ = try await DomainRuleUpdater(repository: repository).apply(.block, to: "a.com")
        #expect(repository.replacedRules.isEmpty)
    }

    @Test func reportsUnconfirmedChange() async {
        let repository = StubRepository()
        repository.ignoresRuleChanges = true
        await #expect(throws: APIError.changeNotConfirmed) {
            try await DomainRuleUpdater(repository: repository).apply(.allow, to: "a.com")
        }
    }

    @Test func rejectsInvalidDomainWithoutRequest() async {
        let repository = StubRepository()
        await #expect(throws: APIError.invalidInput) {
            try await DomainRuleUpdater(repository: repository).apply(.block, to: "a.com^$badfilter")
        }
        #expect(repository.replacedRules.isEmpty)
    }

    @Test func modelShowsErrorAndReloadsAfterFailedWrite() async {
        let repository = StubRepository()
        repository.ignoresRuleChanges = true
        let model = DomainRuleModel(domain: "a.com", repository: repository)
        await model.load()
        #expect(model.availableChanges == [.block, .allow])
        await model.perform(.block)
        #expect(model.actionError == .changeNotConfirmed)
        #expect(model.status?.state == DomainRuleState.none)
        #expect(model.confirmedChanges == 0)
    }

    @Test func demoRepositoryKeepsRuleChanges() async throws {
        let updater = DomainRuleUpdater(repository: DemoAdGuardRepository())
        let status = try await updater.apply(.allow, to: "doubleclick.net")
        #expect(status.state == .allowed)
    }
}

struct SetRulesRequestTests {
    @Test func postsRulesAsJSON() async throws {
        let host = "setrules.test"
        StubURLProtocol.register(host: host) { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path() == "/control/filtering/set_rules")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try #require(request.httpBodyStream.map(Self.read))
            let json = try JSONSerialization.jsonObject(with: body) as? [String: [String]]
            #expect(json == ["rules": ["||a.com^$important"]])
            return StubURLProtocol.respond(request, status: 200, body: "OK\n")
        }
        let client = AdGuardAPIClient(baseURL: try #require(URL(string: "https://\(host)")),
                                      credentials: ServerCredentials(username: "u", password: "p"),
                                      session: StubURLProtocol.makeSession())
        try await client.write(.setRules, body: SetRulesRequestDTO(rules: ["||a.com^$important"]))
    }

    @Test func decodesUserRulesFromFilteringStatus() throws {
        let json = Data(#"{"enabled":true,"user_rules":["||a.com^",""]}"#.utf8)
        let dto = try JSONDecoder.adGuard.decode(FilterStatusDTO.self, from: json)
        #expect(dto.userRules == ["||a.com^", ""])
    }

    private static func read(_ stream: InputStream) -> Data {
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
