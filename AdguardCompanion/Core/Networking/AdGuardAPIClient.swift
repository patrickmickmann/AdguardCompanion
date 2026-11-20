import Foundation

/// Thin, stateless HTTP client for the AdGuard Home REST API.
/// Requests and responses are never logged, as they may contain credentials
/// or sensitive DNS data.
nonisolated struct AdGuardAPIClient: Sendable {
    let baseURL: URL
    let credentials: ServerCredentials
    let session: URLSession

    init(baseURL: URL, credentials: ServerCredentials, session: URLSession = .adGuard) {
        self.baseURL = baseURL
        self.credentials = credentials
        self.session = session
    }

    /// Performs a GET request and decodes the JSON response off the main actor.
    @concurrent
    func get<Response: Decodable & Sendable>(_ endpoint: Endpoint) async throws(APIError) -> Response {
        var request = URLRequest(url: endpoint.url(relativeTo: baseURL))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(credentials.authorizationHeaderValue, forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError(error)
        }
        try Self.validate(response: response, data: data)
        do {
            return try JSONDecoder.adGuard.decode(Response.self, from: data)
        } catch {
            throw .decodingFailed
        }
    }

    /// Maps non-success HTTP responses to `APIError`.
    static func validate(response: URLResponse, data: Data) throws(APIError) {
        guard let http = response as? HTTPURLResponse else { throw .invalidResponse }
        switch http.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw .unauthorized
        default:
            let body = try? JSONDecoder.adGuard.decode(ErrorDTO.self, from: data)
            throw .http(statusCode: http.statusCode, message: body?.message)
        }
    }
}

nonisolated extension JSONDecoder {
    static var adGuard: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
