import Foundation
import Testing
@testable import AdguardCompanion

struct AdGuardAPIClientTests {
    private let credentials = ServerCredentials(username: "admin", password: "s3cret")

    private func client(host: String) -> AdGuardAPIClient {
        AdGuardAPIClient(
            baseURL: URL(string: "https://\(host)") ?? URL(fileURLWithPath: "/"),
            credentials: credentials,
            session: StubURLProtocol.makeSession()
        )
    }

    @Test func sendsBasicAuthAndDecodesStatus() async throws {
        let host = "status.test"
        StubURLProtocol.register(host: host) { request in
            #expect(request.url?.path() == "/control/status")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Basic YWRtaW46czNjcmV0")
            return StubURLProtocol.respond(request, status: 200,
                                           body: #"{"version":"v0.107.57","running":true,"protection_enabled":true}"#)
        }
        let dto: ServerStatusDTO = try await client(host: host).get(.status)
        #expect(dto.version == "v0.107.57")
        #expect(dto.protectionEnabled == true)
    }

    @Test func unauthorizedStatusMapsToUnauthorized() async {
        let host = "unauthorized.test"
        StubURLProtocol.register(host: host) { StubURLProtocol.respond($0, status: 401, body: "") }
        await #expect(throws: APIError.unauthorized) {
            let _: ServerStatusDTO = try await client(host: host).get(.status)
        }
    }

    @Test func serverErrorCarriesMessage() async {
        let host = "servererror.test"
        StubURLProtocol.register(host: host) {
            StubURLProtocol.respond($0, status: 500, body: #"{"message":"boom"}"#)
        }
        await #expect(throws: APIError.http(statusCode: 500, message: "boom")) {
            let _: ServerStatusDTO = try await client(host: host).get(.status)
        }
    }

    @Test func invalidPayloadMapsToDecodingFailed() async {
        let host = "html.test"
        StubURLProtocol.register(host: host) { StubURLProtocol.respond($0, status: 200, body: "<html>") }
        await #expect(throws: APIError.decodingFailed) {
            let _: ServerStatusDTO = try await client(host: host).get(.status)
        }
    }

    @Test func transportErrorsAreCategorized() {
        #expect(APIError(URLError(.notConnectedToInternet)) == .offline)
        #expect(APIError(URLError(.timedOut)) == .timeout)
        #expect(APIError(URLError(.cannotConnectToHost)) == .serverUnreachable)
        #expect(APIError(URLError(.serverCertificateUntrusted)) == .secureConnectionFailed)
        #expect(APIError(CancellationError()) == .cancelled)
    }

    @Test func credentialsAreRedactedInDescriptions() {
        #expect(!String(describing: credentials).contains("s3cret"))
        #expect(!String(reflecting: credentials).contains("s3cret"))
    }

    @Test func redirectsAreOnlyAllowedWithinSameOrigin() throws {
        let origin = try #require(URL(string: "https://adguard.home:3000/control/status"))
        let same = try #require(URL(string: "https://adguard.home:3000/login.html"))
        let otherHost = try #require(URL(string: "https://evil.example/control/status"))
        let downgrade = try #require(URL(string: "http://adguard.home:3000/control/status"))
        #expect(SameOriginRedirectPolicy.isAllowed(from: origin, to: same))
        #expect(!SameOriginRedirectPolicy.isAllowed(from: origin, to: otherHost))
        #expect(!SameOriginRedirectPolicy.isAllowed(from: origin, to: downgrade))
    }
}
