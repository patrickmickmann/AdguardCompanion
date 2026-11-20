import Foundation

/// Reads and changes the user-defined rule of a domain.
///
/// `set_rules` replaces the complete rule list, so the current rules are read
/// immediately before writing to keep changes made elsewhere. Success is only
/// reported after reading the rules back from the server.
nonisolated struct DomainRuleUpdater: Sendable {
    let repository: any AdGuardRepository

    struct Status: Equatable, Sendable {
        let state: DomainRuleState
        let rule: String?
    }

    func status(of domain: String) async throws(APIError) -> Status {
        guard let domain = CustomDomainRules.normalizedDomain(domain) else { throw .invalidInput }
        return Self.status(of: domain, in: try await repository.fetchUserRules())
    }

    func apply(_ change: DomainRuleChange, to domain: String) async throws(APIError) -> Status {
        guard let domain = CustomDomainRules.normalizedDomain(domain) else { throw .invalidInput }
        let current = try await repository.fetchUserRules()
        let updated = CustomDomainRules.applying(change, to: domain, in: current)
        if updated != current {
            try await repository.replaceUserRules(updated)
        }
        let confirmed = Self.status(of: domain, in: try await repository.fetchUserRules())
        guard confirmed.state == change.resultingState else { throw .changeNotConfirmed }
        return confirmed
    }

    private static func status(of domain: String, in rules: [String]) -> Status {
        Status(state: CustomDomainRules.state(of: domain, in: rules),
               rule: CustomDomainRules.matchingRule(for: domain, in: rules))
    }
}
