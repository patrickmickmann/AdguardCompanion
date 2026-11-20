import Foundation

/// Whether a user-defined rule currently blocks or allows a domain.
nonisolated enum DomainRuleState: Equatable, Sendable {
    case none, blocked, allowed
}

/// A change to the user-defined rule of one domain.
nonisolated enum DomainRuleChange: Equatable, Sendable {
    case block, allow, remove

    var resultingState: DomainRuleState {
        switch self {
        case .block: .blocked
        case .allow: .allowed
        case .remove: .none
        }
    }
}

/// Builds and recognizes the per-domain rules in AdGuard Home's user rules.
/// Uses the same rules as the AdGuard Home web interface (`||domain^$important`
/// and `@@||domain^$important`), so changes made in either place are recognized.
/// Plain `||domain^` variants are recognized too; unrelated rules are never touched.
nonisolated enum CustomDomainRules {
    /// Lowercased host name without trailing dot, or `nil` if the input could
    /// inject rule syntax (`|`, `^`, `$`, `/`, spaces …) or is not a host name.
    static func normalizedDomain(_ input: String) -> String? {
        var domain = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if domain.hasSuffix(".") { domain.removeLast() }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_.")
        guard !domain.isEmpty, domain.count <= 253,
              domain.unicodeScalars.allSatisfy(allowed.contains),
              !domain.hasPrefix("."), !domain.contains("..") else { return nil }
        return domain
    }

    static func blockRule(for domain: String) -> String { "||\(domain)^$important" }
    static func allowRule(for domain: String) -> String { "@@||\(domain)^$important" }

    private static func blockVariants(for domain: String) -> Set<String> {
        [blockRule(for: domain), "||\(domain)^"]
    }

    private static func allowVariants(for domain: String) -> Set<String> {
        [allowRule(for: domain), "@@||\(domain)^"]
    }

    /// Allow rules win over block rules in AdGuard Home, so they are checked first.
    static func state(of domain: String, in rules: [String]) -> DomainRuleState {
        let trimmed = Set(rules.map { $0.trimmingCharacters(in: .whitespaces) })
        if !trimmed.isDisjoint(with: allowVariants(for: domain)) { return .allowed }
        if !trimmed.isDisjoint(with: blockVariants(for: domain)) { return .blocked }
        return .none
    }

    /// The rule that currently decides the domain, for display.
    static func matchingRule(for domain: String, in rules: [String]) -> String? {
        let candidates = allowVariants(for: domain).union(blockVariants(for: domain))
        return rules.first { candidates.contains($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// Returns `rules` with the domain's own rules replaced according to `change`.
    /// Order and all other rules, including comments, are preserved.
    static func applying(_ change: DomainRuleChange, to domain: String, in rules: [String]) -> [String] {
        let owned = allowVariants(for: domain).union(blockVariants(for: domain))
        var result = rules.filter { !owned.contains($0.trimmingCharacters(in: .whitespaces)) }
        switch change {
        case .block: result.append(blockRule(for: domain))
        case .allow: result.append(allowRule(for: domain))
        case .remove: break
        }
        return result
    }
}
