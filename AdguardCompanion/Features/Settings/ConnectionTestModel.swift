import Foundation
import Observation

/// Runs a read-only connection test (`GET /control/status`) and measures latency.
@Observable
final class ConnectionTestModel {
    enum State: Equatable {
        case idle
        case testing
        case succeeded(ServerStatus, latency: Duration)
        case failed(APIError)
    }

    private(set) var state: State = .idle
    private let repository: any AdGuardRepository
    private let clock = ContinuousClock()

    init(repository: any AdGuardRepository) {
        self.repository = repository
    }

    var status: ServerStatus? {
        if case let .succeeded(status, _) = state { return status }
        return nil
    }

    func run() async {
        guard state != .testing else { return }
        state = .testing
        let start = clock.now
        do {
            let status = try await repository.fetchServerStatus()
            state = .succeeded(status, latency: clock.now - start)
        } catch {
            state = error == .cancelled ? .idle : .failed(error)
        }
    }
}
