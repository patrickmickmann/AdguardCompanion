import Foundation
import Testing
@testable import AdguardCompanion

struct QueryLogGroupingTests {
    private let base = Date(timeIntervalSince1970: 1_795_178_400) // a full minute

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    private func entry(_ domain: String, type: String, offset: TimeInterval,
                       client: String = "10.0.0.2", outcome: QueryOutcome = .allowed) -> QueryLogEntry {
        QueryLogEntry(
            id: "\(domain)-\(type)-\(offset)", date: base.addingTimeInterval(offset), domain: domain,
            queryType: type, client: QueryClient(address: client, name: nil, organization: nil),
            outcome: outcome, rules: [], serviceName: nil, responseStatus: nil,
            answers: [DNSAnswerRecord(type: type, value: "x", ttl: nil)], upstream: nil,
            isCached: false, isDNSSECAuthenticated: false, elapsed: nil, clientProtocol: nil
        )
    }

    @Test func mergesSimultaneousTypesForSameDomainAndClient() {
        let groups = QueryLogGrouping.groups(from: [
            entry("a.com", type: "AAAA", offset: 30), entry("a.com", type: "A", offset: 30),
            entry("a.com", type: "HTTPS", offset: 29.5),
        ])
        #expect(groups.count == 1)
        #expect(groups[0].queryTypes == ["A", "AAAA", "HTTPS"])
    }

    @Test func keepsDifferentClientsOutcomesAndLaterRepeatsApart() {
        let groups = QueryLogGrouping.groups(from: [
            entry("a.com", type: "A", offset: 30),
            entry("a.com", type: "AAAA", offset: 30, client: "10.0.0.3"),
            entry("a.com", type: "A", offset: 30, client: "10.0.0.3", outcome: .blocked(.filterRule)),
            entry("a.com", type: "A", offset: 20, client: "10.0.0.3", outcome: .blocked(.filterRule)),
        ])
        #expect(groups.count == 4)
    }

    @Test func mergesDualStackDeviceWithSameName() {
        func named(_ type: String, _ address: String) -> QueryLogEntry {
            let base = entry("a.com", type: type, offset: 30, client: address)
            return QueryLogEntry(
                id: base.id + address, date: base.date, domain: base.domain, queryType: type,
                client: QueryClient(address: address, name: "iPad.fritz.box", organization: nil),
                outcome: .allowed, rules: [], serviceName: nil, responseStatus: nil, answers: [],
                upstream: nil, isCached: false, isDNSSECAuthenticated: false, elapsed: nil, clientProtocol: nil
            )
        }
        let groups = QueryLogGrouping.groups(from: [named("A", "10.0.0.2"), named("AAAA", "fd00::2")])
        #expect(groups.count == 1)
    }

    @Test func sectionsSplitByMinute() {
        let groups = QueryLogGrouping.groups(from: [
            entry("a.com", type: "A", offset: 70), entry("b.com", type: "A", offset: 65),
            entry("c.com", type: "A", offset: 10),
        ])
        let sections = QueryLogGrouping.sections(from: groups, calendar: utc)
        #expect(sections.map(\.groups.count) == [2, 1])
        #expect(sections.first?.minute == base.addingTimeInterval(60))
    }
}

struct DisplayNameTests {
    @Test(arguments: [
        ("browser-intake.datadoghq.com", "browser-intake.", "datadoghq.com"),
        ("example.com", "", "example.com"),
        ("news.bbc.co.uk", "news.", "bbc.co.uk"),
        ("bbc.co.uk", "bbc.", "co.uk"),
        ("localhost", "", "localhost"),
    ])
    func splitsDomain(domain: String, prefix: String, base: String) {
        #expect(DomainDisplayParts(domain: domain) == DomainDisplayParts(prefix: prefix, base: base))
    }

    @Test func stripsRouterSuffixes() {
        #expect(DeviceName.readable("iPad.fritz.box") == "iPad")
        #expect(DeviceName.readable("Mac-mini-von-Alex.fritz.box") == "Mac-mini-von-Alex")
        #expect(DeviceName.readable("nas.local") == "nas")
        #expect(DeviceName.readable("printer.home.arpa") == "printer")
    }

    @Test func hidesMachineIdentifiersAndEmptyNames() {
        #expect(DeviceName.readable("20c62acf47c34bc0b6ee631c2b590712") == nil)
        #expect(DeviceName.readable("") == nil)
        #expect(DeviceName.readable(nil) == nil)
        #expect(DeviceName.readable("cafe") == "cafe")
    }

    @Test func clientFallsBackToAddress() {
        let client = QueryClient(address: "10.0.0.9", name: "0123456789abcdef0123", organization: nil)
        #expect(client.displayName == "10.0.0.9")
    }
}
