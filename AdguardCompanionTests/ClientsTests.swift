import Foundation
import Testing
@testable import AdguardCompanion

struct ClientsMapperTests {
    private func persistent(_ name: String, ids: [String], global: Bool? = true) -> PersistentClientDTO {
        PersistentClientDTO(
            name: name, ids: ids, useGlobalSettings: global, filteringEnabled: true, parentalEnabled: nil,
            safebrowsingEnabled: false, safeSearch: nil, useGlobalBlockedServices: nil,
            blockedServices: nil, upstreams: ["", "1.1.1.1"], tags: nil, ignoreQuerylog: nil, ignoreStatistics: true
        )
    }

    private func runtime(_ ip: String, name: String?, source: String? = "rDNS") -> RuntimeClientDTO {
        RuntimeClientDTO(ip: ip, name: name, source: source, whoisInfo: nil)
    }

    @Test func mergesConfiguredAndDiscoveredWithoutDuplicates() {
        let dto = ClientsDTO(
            clients: [persistent("Laptop", ids: ["10.0.0.2", "fd00::2"])],
            autoClients: [runtime("10.0.0.2", name: "laptop.home.arpa"), runtime("10.0.0.3", name: "iPad.home.arpa")]
        )
        let clients = ClientsMapper.map(dto, topClients: [])
        #expect(clients.map(\.name) == ["iPad", "Laptop"])
        #expect(clients.filter(\.isConfigured).count == 1)
    }

    @Test func sumsRequestCountsOverAllAddressesAndSortsByActivity() {
        let dto = ClientsDTO(
            clients: [persistent("Laptop", ids: ["10.0.0.2", "fd00::2"])],
            autoClients: [runtime("10.0.0.3", name: nil), runtime("10.0.0.4", name: "Quiet")]
        )
        let top = [RankedEntry(name: "10.0.0.3", count: 50), RankedEntry(name: "10.0.0.2", count: 30),
                   RankedEntry(name: "fd00::2", count: 40)]
        let clients = ClientsMapper.map(dto, topClients: top)
        #expect(clients.map(\.name) == ["Laptop", "10.0.0.3", "Quiet"])
        #expect(clients[0].requestCount == 70)
        #expect(clients[2].requestCount == nil)
    }

    @Test func mergesDualStackDiscoveredDevicesByName() {
        let dto = ClientsDTO(clients: nil, autoClients: [
            runtime("10.0.0.5", name: "PC.home.arpa"), runtime("fd00::5", name: "PC.home.arpa"),
            runtime("10.0.0.6", name: nil), runtime("10.0.0.7", name: nil),
        ])
        let top = [RankedEntry(name: "10.0.0.5", count: 10), RankedEntry(name: "fd00::5", count: 5)]
        let clients = ClientsMapper.map(dto, topClients: top)
        #expect(clients.count == 3)
        let pc = clients.first { $0.name == "PC" }
        #expect(pc?.identifiers == ["10.0.0.5", "fd00::5"])
        #expect(pc?.requestCount == 15)
    }

    @Test func keepsDistinctDevicesWithSameNameApart() {
        let dto = ClientsDTO(clients: nil, autoClients: [
            runtime("10.0.0.20", name: "iPhone.home.arpa"), runtime("10.0.0.21", name: "iPhone.home.arpa"),
            runtime("fd00::20", name: "iPhone.home.arpa"),
        ])
        let clients = ClientsMapper.map(dto, topClients: [])
        // Two IPv4 devices stay separate; the IPv6 address is ambiguous and stays on its own.
        #expect(clients.count == 3)
        #expect(clients.allSatisfy { $0.identifiers.count == 1 })
    }

    @Test func attachesSeveralIPv6AddressesToSingleDevice() {
        let dto = ClientsDTO(clients: nil, autoClients: [
            runtime("fd00::1", name: "PC"), runtime("10.0.0.5", name: "PC"), runtime("2a02::1", name: "PC"),
        ])
        let clients = ClientsMapper.map(dto, topClients: [])
        #expect(clients.count == 1)
        #expect(clients.first?.identifiers == ["10.0.0.5", "fd00::1", "2a02::1"])
    }

    @Test func mapsSettingsAndDefaults() throws {
        let clients = ClientsMapper.map(ClientsDTO(clients: [persistent("A", ids: ["1.2.3.4"], global: nil)],
                                                    autoClients: nil), topClients: [])
        guard case let .configured(settings) = try #require(clients.first).kind else {
            Issue.record("Expected configured client")
            return
        }
        #expect(settings.usesGlobalSettings)
        #expect(settings.usesGlobalBlockedServices)
        #expect(settings.upstreams == ["1.1.1.1"])
        #expect(settings.excludedFromStatistics)
        #expect(!settings.excludedFromQueryLog)
    }

    @Test func mapsDiscoverySources() {
        #expect(DiscoverySource("ARP") == .arp)
        #expect(DiscoverySource("etc/hosts") == .hostsFile)
        #expect(DiscoverySource("New") == .other("New"))
    }

    @Test func decodesRealPayloadShape() throws {
        let json = Data("""
        {"clients":[{"name":"Kids","ids":["192.168.1.9"],"use_global_settings":false,
          "safe_search":{"enabled":true,"google":true},"blocked_services_schedule":{"time_zone":"Local"}}],
         "auto_clients":[{"ip":"192.168.1.5","name":"tv.lan","source":"ARP","whois_info":{}}],
         "supported_tags":["device_tv"]}
        """.utf8)
        let dto = try JSONDecoder.adGuard.decode(ClientsDTO.self, from: json)
        let clients = ClientsMapper.map(dto, topClients: [])
        #expect(clients.count == 2)
        #expect(clients.contains { $0.name == "tv" })
    }
}

@MainActor
struct ClientPresentationTests {
    private func client(_ name: String, ids: [String] = ["10.0.0.1"]) -> NetworkClient {
        NetworkClient(name: name, identifiers: ids, kind: .discovered(source: .arp), whois: [:], requestCount: nil)
    }

    @Test(arguments: [
        ("iPad", "ipad"), ("Mac-mini-von-Alex", "desktopcomputer"), ("MacBook Pro", "laptopcomputer"),
        ("SonosZP", "hifispeaker"), ("Meross-Smart-Plug", "lightbulb"), ("Apple-TV", "appletv"),
        ("DESKTOP-EPT6J1S", "desktopcomputer"), ("Spinner", "network"), ("192.168.1.2", "network"),
    ])
    func derivesSymbol(name: String, symbol: String) {
        #expect(client(name).symbol == symbol)
    }

    @Test func searchableAddressSkipsMACAndCIDR() {
        #expect(client("a", ids: ["a4:83:e7:12:34:56", "10.0.0.0/24", "10.0.0.7"]).searchableAddress == "10.0.0.7")
    }

    @Test func sortsIdentifiersIPv4First() {
        let ids = ["client-id", "fd00::1", "a4:83:e7:12:34:56", "10.0.0.1"]
        #expect(client("x", ids: ids).sortedIdentifiers == ["10.0.0.1", "fd00::1", "client-id", "a4:83:e7:12:34:56"])
    }

    @Test func modelFiltersByNameOrIdentifier() async {
        let model = ClientsModel(repository: StubRepository())
        await model.load()
        #expect(!model.configured.isEmpty)
        model.searchText = "1.23"
        #expect(model.configured.map(\.name) == ["Kinder-iPad"])
        #expect(model.discovered.isEmpty)
    }
}

@MainActor
struct ClientRefinementTests {
    private func client(_ name: String, ids: [String], count: Int? = nil) -> NetworkClient {
        NetworkClient(name: name, identifiers: ids, kind: .discovered(source: .arp), whois: [:], requestCount: count)
    }

    @Test func exactTermQuotesAndParses() {
        #expect(QueryLogQuery.exactTerm("10.0.0.1") == "\"10.0.0.1\"")
        #expect(QueryLogQuery.parse("\"10.0.0.1\"") == ("10.0.0.1", true))
        #expect(QueryLogQuery.parse("10.0.0.1") == ("10.0.0.1", false))
    }

    @Test func demoExactSearchDoesNotMatchPrefixes() async throws {
        let page = try await DemoAdGuardRepository().fetchQueryLog(QueryLogQuery(search: "\"192.168.1.1\""))
        #expect(page.entries.isEmpty)
        let exact = try await DemoAdGuardRepository().fetchQueryLog(QueryLogQuery(search: "\"192.168.1.12\""))
        #expect(!exact.entries.isEmpty)
        #expect(exact.entries.allSatisfy { $0.client.address == "192.168.1.12" })
    }

    @Test func unnamedClientsGetNeutralTitleAndAddressSubtitle() {
        let unnamed = client("10.0.0.9", ids: ["10.0.0.9"])
        #expect(!unnamed.hasName)
        #expect(unnamed.displayTitle == "Unbekanntes Gerät")
        #expect(unnamed.secondaryIdentifier == "10.0.0.9")
        let named = client("iPad", ids: ["10.0.0.8"])
        #expect(named.displayTitle == "iPad")
        #expect(named.secondaryIdentifier == "10.0.0.8")
    }

    @Test func sortsByNameWithUnnamedLast() {
        let sorted = ClientsMapper.sortedByName([
            client("10.0.0.2", ids: ["10.0.0.2"]), client("zeta", ids: ["1"]), client("Alpha", ids: ["2"]),
        ])
        #expect(sorted.map(\.name) == ["Alpha", "zeta", "10.0.0.2"])
    }

    @Test func lastActivityPicksNewestAcrossAddresses() async throws {
        let model = ClientsModel(repository: StubRepository())
        let latest = try await model.lastActivity(of: client("iPhone", ids: ["192.168.1.12", "fd00::12"]))
        #expect(latest?.client.address == "192.168.1.12")
        let none = try await model.lastActivity(of: client("Ghost", ids: ["10.9.9.9"]))
        #expect(none == nil)
    }
}
