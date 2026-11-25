import Foundation

/// Non-secret connection parameters. The password is stored separately in the Keychain.
nonisolated struct ServerConfiguration: Codable, Equatable, Sendable {
    let baseURL: URL
    let username: String

    var keychainAccount: String { "\(username)@\(baseURL.absoluteString)" }
}

/// How the app is connected.
enum ConnectionMode: Equatable {
    case server(ServerConfiguration)
    case demo
}

enum ConnectionStoreError: Error, Equatable {
    case keychain(KeychainError)
    case missingPassword
}

/// Persists the connection: configuration in UserDefaults, password in the Keychain.
struct ConnectionStore {
    private let defaults: UserDefaults
    private let keychain: KeychainStore

    private enum Key {
        static let configuration = "connection.configuration"
        static let demoMode = "connection.demoMode"
    }

    init(defaults: UserDefaults = .standard, keychain: KeychainStore = .serverCredentials) {
        self.defaults = defaults
        self.keychain = keychain
    }

    func loadMode() -> ConnectionMode? {
        if let data = defaults.data(forKey: Key.configuration),
           let configuration = try? JSONDecoder().decode(ServerConfiguration.self, from: data) {
            return .server(configuration)
        }
        return defaults.bool(forKey: Key.demoMode) ? .demo : nil
    }

    func credentials(for configuration: ServerConfiguration) throws(ConnectionStoreError) -> ServerCredentials {
        let password: String?
        do {
            password = try keychain.password(account: configuration.keychainAccount)
        } catch {
            throw .keychain(error)
        }
        guard let password else { throw .missingPassword }
        return ServerCredentials(username: configuration.username, password: password)
    }

    func saveServer(_ configuration: ServerConfiguration, password: String) throws(ConnectionStoreError) {
        try clear()
        do {
            try keychain.setPassword(password, account: configuration.keychainAccount)
        } catch {
            throw .keychain(error)
        }
        // Encoding a struct of URL and String cannot fail; a failure would be a programming error.
        if let data = try? JSONEncoder().encode(configuration) {
            defaults.set(data, forKey: Key.configuration)
        }
    }

    func enableDemo() throws(ConnectionStoreError) {
        try clear()
        defaults.set(true, forKey: Key.demoMode)
    }

    func clear() throws(ConnectionStoreError) {
        defaults.removeObject(forKey: Key.configuration)
        defaults.removeObject(forKey: Key.demoMode)
        do {
            try keychain.removeAll()
        } catch {
            throw .keychain(error)
        }
    }
}

extension KeychainStore {
    /// Scoped to the app's bundle identifier, so every installation keeps its own entry.
    static let serverCredentials = KeychainStore(
        service: "\(Bundle.main.bundleIdentifier ?? "AdguardCompanion").server"
    )
}
