import Foundation
import Observation

/// Presentation state of the DNS rewrite list.
@Observable
final class DNSRewritesModel {
    /// What the editor sheet is for.
    enum Editing: Identifiable {
        case new
        case existing(DNSRewrite)

        var id: String {
            switch self {
            case .new: "new"
            case let .existing(rewrite): rewrite.id
            }
        }
    }

    private(set) var settings: DNSRewriteSettings?
    private(set) var loadError: APIError?
    var actionError: APIError?
    private(set) var pendingChange: DNSRewriteChange?
    private(set) var confirmedChanges = 0
    var editing: Editing?
    var rewritePendingRemoval: DNSRewrite?

    let isDemo: Bool
    private let repository: any AdGuardRepository
    private let updater: DNSRewriteUpdater

    init(repository: any AdGuardRepository) {
        self.repository = repository
        self.updater = DNSRewriteUpdater(repository: repository)
        self.isDemo = repository.isDemo
    }

    var isWorking: Bool { pendingChange != nil }

    func load() async {
        do {
            settings = try await repository.fetchRewrites()
            loadError = nil
        } catch {
            guard error != .cancelled else { return }
            loadError = error
        }
    }

    @discardableResult
    func apply(_ change: DNSRewriteChange) async -> Bool {
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

    var areRewritesOn: Bool {
        if case let .setRewritesEnabled(isOn)? = pendingChange { return isOn }
        return settings?.isEnabled ?? false
    }

    func isOn(_ rewrite: DNSRewrite) -> Bool {
        if case let .update(old, new)? = pendingChange, old.matches(rewrite) { return new.isEnabled }
        return rewrite.isEnabled
    }
}
