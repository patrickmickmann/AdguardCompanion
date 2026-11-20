import Foundation
import Observation

/// An established connection the main UI works with.
struct ActiveConnection {
    let repository: any AdGuardRepository
    /// `nil` in demo mode.
    let configuration: ServerConfiguration?

    var isDemo: Bool { repository.isDemo }
}

/// App-wide composition root: owns the connection lifecycle and builds
/// repositories for the feature screens.
@Observable
final class AppModel {
    private(set) var connection: ActiveConnection?
    /// Set when a stored connection could not be restored.
    private(set) var restoreProblem: String?

    private let store: ConnectionStore
    private let session: URLSession

    init(store: ConnectionStore = ConnectionStore(), session: URLSession = .adGuard) {
        self.store = store
        self.session = session
        restore()
    }

    /// Creates a repository for credentials that are not yet stored,
    /// used to verify a connection before saving it.
    func makeRepository(for configuration: ServerConfiguration, password: String) -> any AdGuardRepository {
        let credentials = ServerCredentials(username: configuration.username, password: password)
        return LiveAdGuardRepository(
            client: AdGuardAPIClient(baseURL: configuration.baseURL, credentials: credentials, session: session)
        )
    }

    /// Persists a connection that the server has already confirmed.
    func completeConnection(_ configuration: ServerConfiguration, password: String) throws(ConnectionStoreError) {
        try store.saveServer(configuration, password: password)
        connection = ActiveConnection(
            repository: makeRepository(for: configuration, password: password),
            configuration: configuration
        )
        restoreProblem = nil
    }

    func startDemo() throws(ConnectionStoreError) {
        try store.enableDemo()
        connection = ActiveConnection(repository: DemoAdGuardRepository(), configuration: nil)
        restoreProblem = nil
    }

    func disconnect() throws(ConnectionStoreError) {
        try store.clear()
        connection = nil
    }

    private func restore() {
        switch store.loadMode() {
        case .demo:
            connection = ActiveConnection(repository: DemoAdGuardRepository(), configuration: nil)
        case let .server(configuration):
            do {
                let credentials = try store.credentials(for: configuration)
                connection = ActiveConnection(
                    repository: LiveAdGuardRepository(client: AdGuardAPIClient(
                        baseURL: configuration.baseURL, credentials: credentials, session: session
                    )),
                    configuration: configuration
                )
            } catch {
                restoreProblem = "Die gespeicherten Zugangsdaten konnten nicht gelesen werden. Bitte verbinde dich erneut."
            }
        case nil:
            connection = nil
        }
    }
}
