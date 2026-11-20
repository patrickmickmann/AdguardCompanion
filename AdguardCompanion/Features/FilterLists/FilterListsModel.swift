import Foundation
import Observation

/// Presentation state of the filter list management. Switches show the
/// requested value while a change is in flight; everything else shows the
/// server's state as read back after each change.
@Observable
final class FilterListsModel {
    private(set) var settings: FilterListSettings?
    private(set) var loadError: APIError?
    var actionError: APIError?
    private(set) var pendingChange: FilterListChange?
    private(set) var isRefreshing = false
    /// Number of lists that had new rules after the last manual refresh.
    var refreshedCount: Int?
    /// Incremented after each confirmed change; drives success haptics.
    private(set) var confirmedChanges = 0
    var listPendingRemoval: FilterList?
    var addingKind: FilterList.Kind?

    let isDemo: Bool
    private let repository: any AdGuardRepository
    private let updater: FilterListUpdater

    init(repository: any AdGuardRepository) {
        self.repository = repository
        self.updater = FilterListUpdater(repository: repository)
        self.isDemo = repository.isDemo
    }

    var isWorking: Bool { pendingChange != nil || isRefreshing }

    func load() async {
        do {
            settings = try await repository.fetchFilterListSettings()
            loadError = nil
        } catch {
            guard error != .cancelled else { return }
            loadError = error
        }
    }

    /// Applies a change. Returns whether the server confirmed it, so the add
    /// sheet can close only on success.
    @discardableResult
    func apply(_ change: FilterListChange) async -> Bool {
        guard !isWorking, let current = settings else { return false }
        pendingChange = change
        defer { pendingChange = nil }
        do {
            settings = try await updater.apply(change, current: current)
            confirmedChanges += 1
            return true
        } catch {
            actionError = error
            await load()
            return false
        }
    }

    func refreshLists() async {
        guard !isWorking else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let result = try await updater.refreshAll()
            settings = result.settings
            refreshedCount = result.updated
        } catch {
            guard error != .cancelled else { return }
            actionError = error
        }
    }

    func isOn(_ list: FilterList) -> Bool {
        if case let .setEnabled(pending, isOn)? = pendingChange, pending.id == list.id { return isOn }
        return list.isEnabled
    }

    var isFilteringOn: Bool {
        if case let .setFilteringEnabled(isOn)? = pendingChange { return isOn }
        return settings?.isFilteringEnabled ?? false
    }

    var isAdding: Bool {
        if case .add? = pendingChange { true } else { false }
    }
}
