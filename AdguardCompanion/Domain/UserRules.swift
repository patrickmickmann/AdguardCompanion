import Foundation

/// What a user rule does, recognized for the common domain rule forms.
nonisolated enum UserRuleKind: Equatable, Sendable {
    case block(domain: String)
    case allow(domain: String)
    case comment
    case other

    init(_ rule: String) {
        let text = rule.trimmingCharacters(in: .whitespaces)
        if UserRulesUpdater.isComment(text) {
            self = .comment
        } else if text.hasPrefix("@@||"), let domain = Self.domain(in: text.dropFirst(4)) {
            self = .allow(domain: domain)
        } else if text.hasPrefix("||"), let domain = Self.domain(in: text.dropFirst(2)) {
            self = .block(domain: domain)
        } else {
            self = .other
        }
    }

    /// The host before "^", if the rest is only an option list ("$…").
    private static func domain(in text: Substring) -> String? {
        guard let caret = text.firstIndex(of: "^") else { return nil }
        let rest = text[text.index(after: caret)...]
        guard rest.isEmpty || rest.hasPrefix("$") else { return nil }
        return CustomDomainRules.normalizedDomain(String(text[..<caret]))
    }
}

/// Adds and removes single user rules. `set_rules` replaces the whole list,
/// so the rules are read right before every write and the result is read
/// back; success is reported only if the server shows the change.
nonisolated struct UserRulesUpdater: Sendable {
    let repository: any AdGuardRepository

    static let maximumLength = 1024

    /// Trimmed single-line rule, or `nil` if it is empty, multi-line or too long.
    static func normalizedRule(_ input: String) -> String? {
        let rule = input.trimmingCharacters(in: .whitespaces)
        guard !rule.isEmpty, rule.count <= maximumLength, !rule.contains(where: \.isNewline) else { return nil }
        return rule
    }

    /// Comments start with "!" or "#" and have no effect.
    static func isComment(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("!") || trimmed.hasPrefix("#")
    }

    func add(_ input: String) async throws(APIError) -> [String] {
        guard let rule = Self.normalizedRule(input) else { throw .invalidInput }
        let current = try await repository.fetchUserRules()
        if !current.contains(rule) {
            try await repository.replaceUserRules(current + [rule])
        }
        let confirmed = try await repository.fetchUserRules()
        guard confirmed.contains(rule) else { throw .changeNotConfirmed }
        return confirmed
    }

    func remove(_ rule: String) async throws(APIError) -> [String] {
        let current = try await repository.fetchUserRules()
        let updated = current.filter { $0 != rule }
        if updated != current {
            try await repository.replaceUserRules(updated)
        }
        let confirmed = try await repository.fetchUserRules()
        guard !confirmed.contains(rule) else { throw .changeNotConfirmed }
        return confirmed
    }
}
