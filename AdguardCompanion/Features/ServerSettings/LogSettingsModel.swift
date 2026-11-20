import Foundation
import Observation

/// Presentation state of the query log or statistics configuration. Every
/// edit is saved immediately and shown as done only after reading it back.
@Observable
final class LogSettingsModel {
    let kind: LogKind
    private(set) var settings: LogSettings?
    /// The edited settings while they are being saved.
    private(set) var pending: LogSettings?
    private(set) var loadError: APIError?
    var actionError: APIError?
    private(set) var confirmedChanges = 0
    private(set) var isClearing = false
    var isConfirmingClear = false
    var newIgnoredDomain = ""

    let isDemo: Bool
    private let repository: any AdGuardRepository
    private let updater: LogSettingsUpdater

    init(kind: LogKind, repository: any AdGuardRepository) {
        self.kind = kind
        self.repository = repository
        self.updater = LogSettingsUpdater(repository: repository)
        self.isDemo = repository.isDemo
    }

    var isWorking: Bool { pending != nil || isClearing }
    /// What the controls show: the edit in flight, otherwise the server's state.
    var displayed: LogSettings? { pending ?? settings }

    func load() async {
        do {
            settings = try await repository.fetchLogSettings(kind)
            loadError = nil
        } catch {
            guard error != .cancelled else { return }
            loadError = error
        }
    }

    /// Applies `edit` to the current settings and saves the result.
    @discardableResult
    func update(_ edit: (inout LogSettings) -> Void) async -> Bool {
        guard !isWorking, var edited = settings else { return false }
        edit(&edited)
        guard edited != settings else { return true }
        pending = edited
        defer { pending = nil }
        do {
            settings = try await updater.save(edited)
            confirmedChanges += 1
            return true
        } catch {
            actionError = error
            await load()
            return false
        }
    }

    var canAddIgnoredDomain: Bool {
        guard let domain = DNSRewriteInput.normalizedDomain(newIgnoredDomain) else { return false }
        return !(settings?.ignoredDomains.contains(domain) ?? true)
    }

    func addIgnoredDomain() async {
        guard canAddIgnoredDomain, let domain = DNSRewriteInput.normalizedDomain(newIgnoredDomain) else { return }
        if await update({ $0.ignoredDomains.append(domain) }) { newIgnoredDomain = "" }
    }

    func clearData() async {
        guard !isWorking else { return }
        isClearing = true
        defer { isClearing = false }
        do {
            try await repository.clearLogData(kind)
            confirmedChanges += 1
        } catch {
            actionError = error
        }
    }
}
