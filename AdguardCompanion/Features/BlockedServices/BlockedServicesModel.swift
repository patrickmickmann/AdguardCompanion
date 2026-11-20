import Foundation
import Observation

/// Presentation state of the globally blocked services.
@Observable
final class BlockedServicesModel {
    private(set) var services: BlockedServices?
    private(set) var loadError: APIError?
    var actionError: APIError?
    /// The set being applied; switches show it until the server confirms.
    private(set) var pendingIDs: Set<String>?
    private(set) var confirmedChanges = 0
    var searchText = ""

    let isDemo: Bool
    private let repository: any AdGuardRepository
    private let updater: BlockedServicesUpdater

    init(repository: any AdGuardRepository) {
        self.repository = repository
        self.updater = BlockedServicesUpdater(repository: repository)
        self.isDemo = repository.isDemo
    }

    var isWorking: Bool { pendingIDs != nil }
    var blockedCount: Int { (pendingIDs ?? services?.blockedIDs ?? []).count }

    func load() async {
        do {
            services = try await repository.fetchBlockedServices()
            loadError = nil
        } catch {
            guard error != .cancelled else { return }
            loadError = error
        }
    }

    func isBlocked(_ service: BlockableService) -> Bool {
        (pendingIDs ?? services?.blockedIDs ?? []).contains(service.id)
    }

    func setBlocked(_ service: BlockableService, _ isBlocked: Bool) async {
        guard !isWorking, let current = services else { return }
        var ids = current.blockedIDs
        if isBlocked { ids.insert(service.id) } else { ids.remove(service.id) }
        pendingIDs = ids
        defer { pendingIDs = nil }
        do {
            services = try await updater.set(ids, current: current)
            confirmedChanges += 1
        } catch {
            actionError = error
            await load()
        }
    }
}
