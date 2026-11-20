import Foundation

/// AdGuard Home administrator credentials used for HTTP Basic authentication.
/// The description is redacted so credentials never end up in logs or dumps.
nonisolated struct ServerCredentials: Sendable, Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    let username: String
    let password: String

    var authorizationHeaderValue: String {
        let token = Data("\(username):\(password)".utf8).base64EncodedString()
        return "Basic \(token)"
    }

    var description: String { "ServerCredentials(<redacted>)" }
    var debugDescription: String { description }
}
