import Foundation

nonisolated extension URLSession {
    /// Ephemeral session for AdGuard Home requests: no cookies, no disk cache,
    /// default certificate validation and a same-origin redirect policy.
    static let adGuard: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = NetworkPolicy.requestTimeout
        configuration.timeoutIntervalForResource = NetworkPolicy.resourceTimeout
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration, delegate: SameOriginRedirectPolicy(), delegateQueue: nil)
    }()
}

nonisolated enum NetworkPolicy {
    /// Idle timeout for ordinary requests, so an unreachable server fails fast.
    static let requestTimeout: TimeInterval = 10
    /// Upper bound for any request, including long-running operations.
    static let resourceTimeout: TimeInterval = 150
    /// Operations where AdGuard Home downloads filter lists before it answers.
    static let longOperationTimeout: TimeInterval = 120
}

/// Prevents the Authorization header from being forwarded to another origin
/// or over a downgraded scheme when the server responds with a redirect.
nonisolated final class SameOriginRedirectPolicy: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        // The completion-handler variant is used deliberately: the async variant
        // currently crashes SILGen (Swift 6.4) when emitting the Objective-C thunk.
        guard let original = task.originalRequest?.url, let target = request.url else {
            completionHandler(nil)
            return
        }
        completionHandler(Self.isAllowed(from: original, to: target) ? request : nil)
    }

    static func isAllowed(from original: URL, to target: URL) -> Bool {
        original.scheme?.lowercased() == target.scheme?.lowercased()
            && original.host()?.lowercased() == target.host()?.lowercased()
            && original.port == target.port
    }
}
