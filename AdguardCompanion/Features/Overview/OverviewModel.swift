import Foundation
import Observation

/// Presentation state of the Overview dashboard. Keeps the last successful
/// snapshot when a refresh fails so stale data can be shown with a hint.
@Observable
final class OverviewModel {
    struct Snapshot: Equatable {
        let status: ServerStatus
        let statistics: DashboardStatistics
        let fetchedAt: Date
    }

    static let refreshInterval: Duration = .seconds(30)

    private(set) var snapshot: Snapshot?
    private(set) var error: APIError?
    private(set) var isRefreshing = false

    let isDemo: Bool
    private let repository: any AdGuardRepository

    init(repository: any AdGuardRepository) {
        self.repository = repository
        self.isDemo = repository.isDemo
    }

    /// Fetches status and statistics in parallel. Overlapping calls are ignored.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            async let status = repository.fetchServerStatus()
            async let statistics = repository.fetchStatistics()
            snapshot = Snapshot(status: try await status, statistics: try await statistics, fetchedAt: .now)
            error = nil
        } catch {
            let apiError = APIError(error)
            guard apiError != .cancelled else { return }
            self.error = apiError
        }
    }

    /// Refreshes immediately and then periodically until the calling task is cancelled
    /// (SwiftUI cancels it when the screen disappears).
    func runAutoRefresh() async {
        while !Task.isCancelled {
            await refresh()
            do {
                try await Task.sleep(for: Self.refreshInterval)
            } catch {
                return
            }
        }
    }
}
