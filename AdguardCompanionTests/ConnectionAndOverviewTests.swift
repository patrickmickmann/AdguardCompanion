import Foundation
import Testing
@testable import AdguardCompanion

@MainActor
struct ConnectionStoreTests {
    private let defaults: UserDefaults
    private let store: ConnectionStore
    private let configuration = ServerConfiguration(
        baseURL: URL(string: "https://adguard.test") ?? URL(fileURLWithPath: "/"), username: "admin"
    )

    init() throws {
        let suite = "ConnectionStoreTests.\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suite))
        store = ConnectionStore(defaults: defaults, keychain: KeychainStore(service: suite))
    }

    @Test func savesConfigurationAndPasswordSeparately() throws {
        try store.saveServer(configuration, password: "pw")
        #expect(store.loadMode() == .server(configuration))
        #expect(try store.credentials(for: configuration) == ServerCredentials(username: "admin", password: "pw"))
        #expect(defaults.dictionaryRepresentation().values.contains { "\($0)".contains("pw") } == false)
        try store.clear()
    }

    @Test func clearRemovesEverything() throws {
        try store.saveServer(configuration, password: "pw")
        try store.clear()
        #expect(store.loadMode() == nil)
        #expect(throws: ConnectionStoreError.missingPassword) { try store.credentials(for: configuration) }
    }

    @Test func demoModeReplacesServerConnection() throws {
        try store.saveServer(configuration, password: "pw")
        try store.enableDemo()
        #expect(store.loadMode() == .demo)
        #expect(throws: ConnectionStoreError.missingPassword) { try store.credentials(for: configuration) }
        try store.clear()
    }
}

/// Repository stub whose responses can be switched between calls.
@MainActor
final class StubRepository: AdGuardRepository {
    var failure: APIError?
    var isDemo: Bool { false }

    func fetchServerStatus() async throws(APIError) -> ServerStatus {
        if let failure { throw failure }
        return try await DemoAdGuardRepository().fetchServerStatus()
    }

    func fetchStatistics() async throws(APIError) -> DashboardStatistics {
        if let failure { throw failure }
        return try await DemoAdGuardRepository().fetchStatistics()
    }

    var queryLogRequests: [QueryLogQuery] = []

    func fetchQueryLog(_ query: QueryLogQuery) async throws(APIError) -> QueryLogPage {
        queryLogRequests.append(query)
        if let failure { throw failure }
        return try await DemoAdGuardRepository().fetchQueryLog(query)
    }

    func fetchFilterLists() async throws(APIError) -> FilterListCatalog {
        if let failure { throw failure }
        return try await DemoAdGuardRepository().fetchFilterLists()
    }

    func fetchClients() async throws(APIError) -> [NetworkClient] {
        if let failure { throw failure }
        return try await DemoAdGuardRepository().fetchClients()
    }

    func fetchBlockedServiceNames() async throws(APIError) -> [String: String] {
        if let failure { throw failure }
        return try await DemoAdGuardRepository().fetchBlockedServiceNames()
    }

    var userRules: [String] = []
    var replacedRules: [[String]] = []
    /// Simulates a server that accepts writes without applying them.
    var ignoresRuleChanges = false

    func fetchUserRules() async throws(APIError) -> [String] {
        if let failure { throw failure }
        return userRules
    }

    func replaceUserRules(_ rules: [String]) async throws(APIError) {
        if let failure { throw failure }
        replacedRules.append(rules)
        if !ignoresRuleChanges { userRules = rules }
    }

    var protection = ProtectionSettings(protection: .enabled, safeBrowsing: true, parentalControl: false, safeSearch: false)
    var protectionChanges: [ProtectionChange] = []

    func fetchProtectionSettings() async throws(APIError) -> ProtectionSettings {
        if let failure { throw failure }
        return protection
    }

    func updateProtection(_ change: ProtectionChange) async throws(APIError) {
        if let failure { throw failure }
        protectionChanges.append(change)
        guard !ignoresRuleChanges else { return }
        switch change {
        case .enableProtection: protection.protection = .enabled
        case let .pauseProtection(pause): protection.protection = .paused(until: .now + pause.duration.timeInterval)
        case .disableProtection: protection.protection = .disabled
        case let .safeBrowsing(isOn): protection.safeBrowsing = isOn
        case let .parentalControl(isOn): protection.parentalControl = isOn
        case let .safeSearch(isOn): protection.safeSearch = isOn
        }
    }
}

@MainActor
struct OverviewModelTests {
    @Test func loadsSnapshot() async {
        let model = OverviewModel(repository: StubRepository())
        await model.refresh()
        #expect(model.snapshot != nil)
        #expect(model.error == nil)
    }

    @Test func keepsStaleSnapshotWhenRefreshFails() async {
        let repository = StubRepository()
        let model = OverviewModel(repository: repository)
        await model.refresh()
        let first = model.snapshot

        repository.failure = .serverUnreachable
        await model.refresh()
        #expect(model.snapshot == first)
        #expect(model.error == .serverUnreachable)
    }

    @Test func cancellationIsNotShownAsError() async {
        let repository = StubRepository()
        repository.failure = .cancelled
        let model = OverviewModel(repository: repository)
        await model.refresh()
        #expect(model.error == nil)
        #expect(model.snapshot == nil)
    }
}
