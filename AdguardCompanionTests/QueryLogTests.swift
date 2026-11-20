import Foundation
import Testing
@testable import AdguardCompanion

struct QueryLogMapperTests {
    private func item(time: String? = "2026-11-20T13:34:56.123456789+01:00",
                      name: String? = "example.com", unicode: String? = nil,
                      reason: String? = "FilteredBlackList", elapsed: String? = "0.25") -> QueryLogItemDTO {
        QueryLogItemDTO(
            answer: [DNSAnswerDTO(ttl: 60, type: "A", value: "0.0.0.0")], cached: true,
            upstream: "https://dns.quad9.net/dns-query", answerDnssec: false, client: "192.168.1.5",
            clientInfo: QueryLogClientDTO(name: "", whois: QueryLogWhoisDTO(city: nil, country: nil, orgname: "ACME")),
            clientProto: "", elapsedMs: elapsed,
            question: DNSQuestionDTO(class: "IN", name: name, unicodeName: unicode, type: "A"),
            rules: [ResultRuleDTO(filterListId: 1, text: "||example.com^"), ResultRuleDTO(filterListId: 2, text: "")],
            reason: reason, serviceName: "", status: "NOERROR", time: time
        )
    }

    @Test func parsesNanosecondTimestampWithOffset() throws {
        let date = try #require(QueryLogMapper.parseDate("2026-11-20T13:34:56.123456789+01:00"))
        #expect(abs(date.timeIntervalSince1970 - 1_795_178_096.123) < 0.001)
    }

    @Test func parsesTimestampWithoutFraction() {
        #expect(QueryLogMapper.parseDate("2026-11-20T12:34:56Z") != nil)
    }

    @Test func mapsEntryFields() throws {
        let entry = try #require(QueryLogMapper.entry(from: item(), index: 0))
        #expect(entry.domain == "example.com")
        #expect(entry.outcome == .blocked(.filterRule))
        #expect(entry.client.name == nil)
        #expect(entry.client.displayName == "192.168.1.5")
        #expect(entry.client.organization == "ACME")
        #expect(entry.rules == [AppliedRule(text: "||example.com^", filterListID: 1)])
        #expect(entry.serviceName == nil)
        #expect(entry.clientProtocol == nil)
        #expect(entry.elapsed == .microseconds(250))
        #expect(entry.isCached)
    }

    @Test func prefersUnicodeDomainName() {
        let entry = QueryLogMapper.entry(from: item(name: "xn--bcher-kva.de", unicode: "bücher.de"), index: 0)
        #expect(entry?.domain == "bücher.de")
    }

    @Test func skipsItemsWithoutTimeOrDomain() {
        #expect(QueryLogMapper.entry(from: item(time: nil), index: 0) == nil)
        #expect(QueryLogMapper.entry(from: item(name: nil), index: 0) == nil)
    }

    @Test func fullPageKeepsCursorShortPageEnds() {
        let full = QueryLogMapper.map(QueryLogDTO(oldest: "T1", data: [item(), item()]), requestedLimit: 2)
        #expect(full.nextCursor == "T1")
        #expect(Set(full.entries.map(\.id)).count == 2)
        let short = QueryLogMapper.map(QueryLogDTO(oldest: "T1", data: [item()]), requestedLimit: 2)
        #expect(short.nextCursor == nil)
    }

    @Test(arguments: [
        ("NotFilteredNotFound", QueryOutcome.allowed), ("NotFilteredWhiteList", .allowlisted),
        ("FilteredSafeBrowsing", .blocked(.safeBrowsing)), ("FilteredBlockedService", .blocked(.blockedService)),
        ("RewriteEtcHosts", .rewritten(.hostsFile)), ("FilteredSafeSearch", .rewritten(.safeSearch)),
        ("SomethingNew", .unknown("SomethingNew")),
    ])
    func mapsReasons(reason: String, expected: QueryOutcome) {
        #expect(QueryOutcome(reason: reason) == expected)
    }

    @Test func catalogResolvesBuiltInAndListNames() {
        let catalog = FilterListCatalog(FilterStatusDTO(
            enabled: true, filters: [FilterDTO(id: 1, name: "AdGuard DNS filter", enabled: true, rulesCount: 1)],
            whitelistFilters: nil, userRules: nil
        ))
        #expect(catalog.name(for: 1) == "AdGuard DNS filter")
        #expect(catalog.name(for: 0) == "Benutzerdefinierte Regeln")
        #expect(catalog.name(for: 99) == nil)
    }
}

struct QueryLogEndpointTests {
    private let base = URL(string: "http://192.168.1.2") ?? URL(fileURLWithPath: "/")

    @Test func encodesDocumentedParametersAndEscapesPlus() throws {
        let query = QueryLogQuery(search: "  ads ", filter: .allowed, cursor: "2026-11-20T13:34:56.1+01:00")
        let url = Endpoint.queryLog(query).url(relativeTo: base).absoluteString
        #expect(url.hasPrefix("http://192.168.1.2/control/querylog?limit=50"))
        #expect(url.contains("older_than=2026-11-20T13:34:56.1%2B01:00"))
        #expect(url.contains("search=ads"))
        #expect(url.contains("reason=NotFilteredNotFound&reason=NotFilteredWhiteList"))
    }

    @Test func allFilterSendsNoReason() {
        let url = Endpoint.queryLog(QueryLogQuery()).url(relativeTo: base).absoluteString
        #expect(!url.contains("reason="))
        #expect(!url.contains("search="))
    }
}

@MainActor
struct ActivityModelTests {
    @Test func pagesThroughLogWithoutDuplicates() async {
        let model = ActivityModel(repository: StubRepository())
        await model.reload()
        #expect(model.entries.count == QueryLogQuery.pageSize)
        #expect(model.hasMore)
        await model.loadMore()
        await model.loadMore()
        #expect(model.entries.count == DemoQueryLog.entryCount)
        #expect(Set(model.entries.map(\.id)).count == model.entries.count)
        #expect(!model.hasMore)
    }

    @Test func filterAndSearchAreSentToRepository() async {
        let repository = StubRepository()
        let model = ActivityModel(repository: repository)
        model.filter = .blocked
        model.searchText = " doubleclick "
        await model.reload()
        #expect(repository.queryLogRequests.last?.filter == .blocked)
        #expect(repository.queryLogRequests.last?.search == "doubleclick")
        #expect(model.entries.allSatisfy { $0.domain == "doubleclick.net" && $0.outcome.isBlocked })
    }

    @Test func loadIfNeededSkipsUnchangedQuery() async {
        let repository = StubRepository()
        let model = ActivityModel(repository: repository)
        await model.loadIfNeeded()
        await model.loadIfNeeded()
        #expect(repository.queryLogRequests.count == 1)
        model.filter = .rewritten
        await model.loadIfNeeded()
        #expect(repository.queryLogRequests.count == 2)
    }

    @Test func errorWithoutEntriesIsExposed() async {
        let repository = StubRepository()
        repository.failure = .unauthorized
        let model = ActivityModel(repository: repository)
        await model.reload()
        #expect(model.error == .unauthorized)
        #expect(model.entries.isEmpty)
    }
}
