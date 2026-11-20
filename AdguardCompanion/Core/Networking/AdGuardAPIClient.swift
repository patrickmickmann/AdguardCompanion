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
        let data = try await send(makeRequest(endpoint, method: "GET"))
        do {
            return try JSONDecoder.adGuard.decode(Response.self, from: data)
        } catch {
            throw .decodingFailed
        }
    }

    /// HTTP methods used for changes.
    enum WriteMethod: String, Sendable {
        case post = "POST", put = "PUT"
    }

    /// Performs a write request with an optional JSON body. Success means a
    /// 2xx status; the response body is not interpreted, callers confirm the
    /// new server state with a subsequent read.
    @concurrent
    func write(_ endpoint: Endpoint, method: WriteMethod = .post,
               body: (any Encodable & Sendable)? = nil) async throws(APIError) {
        _ = try await send(writeRequest(endpoint, method: method, body: body))
    }

    /// Write request whose JSON response is decoded, e.g. a refresh result.
    @concurrent
    func write<Response: Decodable & Sendable>(
        _ endpoint: Endpoint, body: (any Encodable & Sendable)?, returning: Response.Type
    ) async throws(APIError) -> Response {
        let data = try await send(writeRequest(endpoint, method: .post, body: body))
        do {
            return try JSONDecoder.adGuard.decode(Response.self, from: data)
        } catch {
            throw .decodingFailed
        }
    }

    private func writeRequest(_ endpoint: Endpoint, method: WriteMethod,
                              body: (any Encodable & Sendable)?) throws(APIError) -> URLRequest {
        var request = makeRequest(endpoint, method: method.rawValue)
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try JSONEncoder.adGuard.encode(body)
            } catch {
                throw .invalidInput
            }
        }
        return request
    }

    private func makeRequest(_ endpoint: Endpoint, method: String) -> URLRequest {
        var request = URLRequest(url: endpoint.url(relativeTo: baseURL))
        request.httpMethod = method
        if let timeout = endpoint.timeout {
            request.timeoutInterval = timeout
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(credentials.authorizationHeaderValue, forHTTPHeaderField: "Authorization")
        return request
    }

    private func send(_ request: URLRequest) async throws(APIError) -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError(error)
        }
        try Self.validate(response: response, data: data)
        return data
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

nonisolated extension JSONEncoder {
    static var adGuard: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

nonisolated extension JSONDecoder {
    static var adGuard: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
