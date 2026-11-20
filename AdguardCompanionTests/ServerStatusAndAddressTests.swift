import Foundation
import Testing
@testable import AdguardCompanion

struct ServerStatusMapperTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func dto(enabled: Bool?, pause: Int64?) -> ServerStatusDTO {
        ServerStatusDTO(
            version: "v0.107.57", running: true, protectionEnabled: enabled,
            protectionDisabledDuration: pause, dnsAddresses: ["10.0.0.2"], dnsPort: 53,
            httpPort: 80, startTime: 1_700_000_000_000
        )
    }

    @Test func enabledProtection() {
        #expect(ServerStatusMapper.map(dto(enabled: true, pause: 0), now: now).filtering == .enabled)
    }

    @Test func pausedProtectionComputesEndDate() {
        let status = ServerStatusMapper.map(dto(enabled: false, pause: 60_000), now: now)
        #expect(status.filtering == .paused(until: now.addingTimeInterval(60)))
    }

    @Test func disabledProtectionWithoutPause() {
        #expect(ServerStatusMapper.map(dto(enabled: false, pause: 0), now: now).filtering == .disabled)
    }

    @Test func startTimeIsMilliseconds() {
        let status = ServerStatusMapper.map(dto(enabled: true, pause: nil), now: now)
        #expect(status.startedAt == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test func emptyPayloadDoesNotClaimRunningOrVersion() throws {
        let dto = try JSONDecoder.adGuard.decode(ServerStatusDTO.self, from: Data("{}".utf8))
        let status = ServerStatusMapper.map(dto, now: now)
        #expect(status.isDNSRunning == false)
        #expect(status.version == nil)
    }
}

struct ServerAddressTests {
    @Test(arguments: [
        ("adguard.home:3000", "https://adguard.home:3000"),
        ("  https://adguard.home/  ", "https://adguard.home"),
        ("HTTP://192.168.1.2:8080/control/", "http://192.168.1.2:8080"),
        ("https://proxy.example/adguard/", "https://proxy.example/adguard"),
    ])
    func normalizesValidInput(input: String, expected: String) throws {
        #expect(try ServerAddress.parse(input).absoluteString == expected)
    }

    @Test func rejectsEmptyInput() {
        #expect(throws: ServerAddressError.empty) { try ServerAddress.parse("   ") }
    }

    @Test func rejectsUnsupportedScheme() {
        #expect(throws: ServerAddressError.unsupportedScheme) { try ServerAddress.parse("ftp://host") }
    }

    @Test(arguments: ["https://", "https://user:pw@host", "https://host?x=1", "https://ho st"])
    func rejectsInvalidInput(input: String) {
        #expect(throws: (any Error).self) { try ServerAddress.parse(input) }
    }

    @Test func detectsExplicitScheme() {
        #expect(ServerAddress.hasExplicitScheme(" http://192.168.1.2"))
        #expect(!ServerAddress.hasExplicitScheme("192.168.1.2"))
    }

    @Test @MainActor func suggestsHTTPOnlyWhenSchemeWasImplicit() {
        let hinted = ConnectionSetupModel.failureMessage(for: .secureConnectionFailed, schemeWasImplicit: true)
        #expect(hinted.contains("http://"))
        let explicit = ConnectionSetupModel.failureMessage(for: .secureConnectionFailed, schemeWasImplicit: false)
        #expect(explicit == APIError.secureConnectionFailed.message)
        let auth = ConnectionSetupModel.failureMessage(for: .unauthorized, schemeWasImplicit: true)
        #expect(auth == APIError.unauthorized.message)
    }

    @Test func detectsInsecureScheme() throws {
        #expect(ServerAddress.isInsecure(try ServerAddress.parse("http://host")))
        #expect(!ServerAddress.isInsecure(try ServerAddress.parse("host")))
    }

    @Test func endpointAppendsToBasePath() throws {
        let base = try ServerAddress.parse("https://proxy.example/adguard")
        #expect(Endpoint.status.url(relativeTo: base).absoluteString == "https://proxy.example/adguard/control/status")
    }
}
