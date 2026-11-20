import Foundation
import Synchronization
import Testing
@testable import AdguardCompanion

@MainActor
struct ProtectionModelTests {
    @Test func confirmsChangesAgainstReadBackSettings() {
        let settings = ProtectionSettings(protection: .paused(until: .now), safeBrowsing: true,
                                          parentalControl: false, safeSearch: true)
        #expect(ProtectionChange.pauseProtection(.oneHour).isConfirmed(by: settings))
        #expect(!ProtectionChange.enableProtection.isConfirmed(by: settings))
        #expect(ProtectionChange.safeSearch(true).isConfirmed(by: settings))
        #expect(!ProtectionChange.parentalControl(true).isConfirmed(by: settings))
    }

    @Test func appliesChangeAndCountsConfirmation() async {
        let repository = StubRepository()
        let model = ProtectionModel(repository: repository)
        await model.load()
        await model.apply(.parentalControl(true))
        #expect(model.settings?.parentalControl == true)
        #expect(model.confirmedChanges == 1)
        #expect(repository.protectionChanges == [.parentalControl(true)])
        #expect(!model.isWorking)
    }

    @Test func unconfirmedChangeShowsErrorAndServerValue() async {
        let repository = StubRepository()
        repository.ignoresRuleChanges = true
        let model = ProtectionModel(repository: repository)
        await model.load()
        await model.apply(.safeBrowsing(false))
        #expect(model.actionError == .changeNotConfirmed)
        #expect(model.isOn(.safeBrowsing))
        #expect(model.confirmedChanges == 0)
    }

    @Test func pauseDurationsAreMilliseconds() {
        #expect(ProtectionPause.oneMinute.milliseconds == 60_000)
        #expect(ProtectionPause.oneDay.milliseconds == 86_400_000)
    }

    @Test func demoPauseExpires() async throws {
        let repository = DemoAdGuardRepository()
        try await repository.updateProtection(.pauseProtection(.oneMinute))
        guard case .paused = try await repository.fetchProtectionSettings().protection else {
            Issue.record("Expected paused protection")
            return
        }
        try await repository.updateProtection(.enableProtection)
        #expect(try await repository.fetchServerStatus().filtering == .enabled)
    }
}

struct ProtectionRequestTests {
    private func repository(host: String) throws -> LiveAdGuardRepository {
        LiveAdGuardRepository(client: AdGuardAPIClient(
            baseURL: try #require(URL(string: "https://\(host)")),
            credentials: ServerCredentials(username: "u", password: "p"),
            session: StubURLProtocol.makeSession()
        ))
    }

    @Test func pauseSendsDurationInMilliseconds() async throws {
        let host = "pause.test"
        StubURLProtocol.register(host: host) { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path() == "/control/protection")
            let json = try JSONSerialization.jsonObject(with: Self.body(of: request)) as? [String: Any]
            #expect(json?["enabled"] as? Bool == false)
            #expect(json?["duration"] as? Int == 600_000)
            return StubURLProtocol.respond(request, status: 200, body: "")
        }
        try await repository(host: host).updateProtection(.pauseProtection(.tenMinutes))
    }

    @Test func safeSearchKeepsEngineSettings() async throws {
        let host = "safesearch.test"
        let sent = Mutex<[String: Bool]?>(nil)
        StubURLProtocol.register(host: host) { request in
            if request.httpMethod == "GET" {
                return StubURLProtocol.respond(request, status: 200,
                                               body: #"{"enabled":false,"google":true,"youtube":false,"newengine":true}"#)
            }
            #expect(request.httpMethod == "PUT")
            #expect(request.url?.path() == "/control/safesearch/settings")
            let values = try JSONDecoder().decode([String: Bool].self, from: Self.body(of: request))
            sent.withLock { $0 = values }
            return StubURLProtocol.respond(request, status: 200, body: "")
        }
        try await repository(host: host).updateProtection(.safeSearch(true))
        #expect(sent.withLock { $0 } == ["enabled": true, "google": true, "youtube": false, "newengine": true])
    }

    @Test func toggleWithoutBodyUsesEnableEndpoint() async throws {
        let host = "safebrowsing.test"
        StubURLProtocol.register(host: host) { request in
            #expect(request.url?.path() == "/control/safebrowsing/enable")
            #expect(request.httpBodyStream == nil && request.httpBody == nil)
            return StubURLProtocol.respond(request, status: 200, body: "OK")
        }
        try await repository(host: host).updateProtection(.safeBrowsing(true))
    }

    private static func body(of request: URLRequest) -> Data {
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
