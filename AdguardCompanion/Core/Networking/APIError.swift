import Foundation

/// Failure categories of a request against the AdGuard Home API.
/// Network, authentication, HTTP and payload errors are kept distinct
/// so the UI can explain what went wrong and what to do next.
nonisolated enum APIError: Error, Equatable, Sendable {
    /// The device has no network connection.
    case offline
    /// The server did not answer in time.
    case timeout
    /// Host not found, refused or otherwise unreachable.
    case serverUnreachable
    /// TLS handshake or certificate validation failed.
    case secureConnectionFailed
    /// HTTP 401/403: credentials were rejected.
    case unauthorized
    /// Any other non-2xx HTTP status with the server's optional error message.
    case http(statusCode: Int, message: String?)
    /// The response was not a valid HTTP response.
    case invalidResponse
    /// The response body could not be decoded into the expected model.
    case decodingFailed
    /// The request was cancelled, e.g. because the screen disappeared.
    case cancelled
    /// Any other transport failure.
    case transport(code: Int)

    /// Wraps an arbitrary error into an `APIError`.
    init(_ error: any Error) {
        switch error {
        case let apiError as APIError:
            self = apiError
        case let urlError as URLError:
            self = APIError.map(urlError)
        case is CancellationError:
            self = .cancelled
        case is DecodingError:
            self = .decodingFailed
        default:
            self = .transport(code: (error as NSError).code)
        }
    }

    static func map(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            .offline
        case .timedOut:
            .timeout
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            .serverUnreachable
        case .secureConnectionFailed, .serverCertificateUntrusted,
             .serverCertificateHasBadDate, .serverCertificateNotYetValid,
             .serverCertificateHasUnknownRoot, .clientCertificateRejected,
             .appTransportSecurityRequiresSecureConnection:
            .secureConnectionFailed
        case .userAuthenticationRequired:
            .unauthorized
        case .cancelled:
            .cancelled
        default:
            .transport(code: error.errorCode)
        }
    }
}
