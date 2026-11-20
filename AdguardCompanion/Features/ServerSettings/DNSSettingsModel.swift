import Foundation
import Observation

/// Presentation state of the DNS settings. Each edit is a partial update
/// that is read back before it is shown as done.
@Observable
final class DNSSettingsModel {
    private(set) var settings: DNSSettings?
    private(set) var pendingPatch: JSONObject?
    private(set) var loadError: APIError?
    var actionError: APIError?
    private(set) var confirmedChanges = 0

    let isDemo: Bool
    let repository: any AdGuardRepository
    private let updater: DNSSettingsUpdater

    init(repository: any AdGuardRepository) {
        self.repository = repository
        self.updater = DNSSettingsUpdater(repository: repository)
        self.isDemo = repository.isDemo
    }

    var isWorking: Bool { pendingPatch != nil }

    /// Settings with the edit in flight applied, so controls follow the tap.
    var displayed: DNSSettings? {
        guard let settings else { return nil }
        guard let pendingPatch else { return settings }
        return DNSSettings(document: settings.document.merging(pendingPatch) { _, new in new })
    }

    func load() async {
        do {
            settings = try await repository.fetchDNSSettings()
            loadError = nil
        } catch {
            guard error != .cancelled else { return }
            loadError = error
        }
    }

    @discardableResult
    func apply(_ patch: JSONObject) async -> Bool {
        guard !isWorking else { return false }
        pendingPatch = patch
        defer { pendingPatch = nil }
        do {
            settings = try await updater.apply(patch)
            confirmedChanges += 1
            return true
        } catch {
            actionError = error
            await load()
            return false
        }
    }
}
