import Foundation
import Observation

/// Presentation state of the Protection tab. Switches show the requested
/// value while a change is in flight and fall back to the server's value
/// if the change fails or is not confirmed.
@Observable
final class ProtectionModel {
    private(set) var settings: ProtectionSettings?
    private(set) var loadError: APIError?
    private(set) var actionError: APIError?
    private(set) var pendingChange: ProtectionChange?
    /// Incremented after each confirmed change; drives success haptics.
    private(set) var confirmedChanges = 0
    var isChoosingPause = false

    let isDemo: Bool
    private let repository: any AdGuardRepository
    private let updater: ProtectionUpdater

    init(repository: any AdGuardRepository) {
        self.repository = repository
        self.updater = ProtectionUpdater(repository: repository)
        self.isDemo = repository.isDemo
    }

    var isWorking: Bool { pendingChange != nil }

    /// End of the current pause, used to reload once it has passed.
    var pausedUntil: Date? {
        if case let .paused(until) = settings?.protection { until } else { nil }
    }

    func load() async {
        do {
            settings = try await repository.fetchProtectionSettings()
            loadError = nil
        } catch {
            guard error != .cancelled else { return }
            loadError = error
        }
    }

    /// Reloads when a pause ends, so the screen does not show a stale pause.
    func reloadWhenPauseEnds() async {
        guard let until = pausedUntil else { return }
        do { try await Task.sleep(for: .seconds(max(until.timeIntervalSinceNow, 0) + 1)) } catch { return }
        await load()
    }

    func apply(_ change: ProtectionChange) async {
        guard !isWorking else { return }
        pendingChange = change
        defer { pendingChange = nil }
        do {
            settings = try await updater.apply(change)
            confirmedChanges += 1
        } catch {
            actionError = error
            await load()
        }
    }

    /// The value a switch shows: the requested one while it is being applied.
    func isOn(_ feature: ProtectionFeature) -> Bool {
        if let pendingChange, let requested = feature.requestedValue(in: pendingChange) { return requested }
        return settings.map(feature.value(in:)) ?? false
    }

    func dismissActionError() {
        actionError = nil
    }
}
