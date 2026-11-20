import Foundation
import Observation

/// Presentation state for blocking or allowing one domain via a user rule.
/// A change is shown as done only after the server confirmed it.
@Observable
final class DomainRuleModel {
    let domain: String
    private(set) var status: DomainRuleUpdater.Status?
    private(set) var loadError: APIError?
    private(set) var actionError: APIError?
    private(set) var isWorking = false
    /// Incremented after each confirmed change; drives success haptics.
    private(set) var confirmedChanges = 0
    /// The change awaiting the user's confirmation.
    var pendingChange: DomainRuleChange?

    private let updater: DomainRuleUpdater
    /// Offers "allow" first for a blocked query, "block" first otherwise.
    private let prefersAllow: Bool

    init(domain: String, repository: any AdGuardRepository, prefersAllow: Bool = false) {
        self.domain = domain
        self.updater = DomainRuleUpdater(repository: repository)
        self.prefersAllow = prefersAllow
    }

    /// Domains that cannot be expressed as a safe rule are not editable.
    var isEditable: Bool { CustomDomainRules.normalizedDomain(domain) != nil }

    /// Changes offered for the current state, most likely first.
    var availableChanges: [DomainRuleChange] {
        switch status?.state {
        case .none?: prefersAllow ? [.allow, .block] : [.block, .allow]
        case .blocked?: [.allow, .remove]
        case .allowed?: [.block, .remove]
        case nil: []
        }
    }

    func load() async {
        guard isEditable else { return }
        do {
            status = try await updater.status(of: domain)
            loadError = nil
        } catch {
            guard error != .cancelled else { return }
            loadError = error
        }
    }

    func perform(_ change: DomainRuleChange) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            status = try await updater.apply(change, to: domain)
            confirmedChanges += 1
        } catch {
            actionError = error
            // Re-read so the displayed state matches the server after a failure.
            await load()
        }
    }

    func dismissActionError() {
        actionError = nil
    }
}
