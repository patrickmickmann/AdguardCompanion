import Foundation
import Network

/// A DNS rewrite: answers for `domain` with `answer` instead of asking upstream.
nonisolated struct DNSRewrite: Hashable, Identifiable, Sendable {
    let domain: String
    /// An IP address, a domain name (CNAME), or "A"/"AAAA" to keep the upstream answer.
    let answer: String
    let isEnabled: Bool

    var id: String { "\(domain)\u{0}\(answer)" }

    func matches(_ other: DNSRewrite) -> Bool { domain == other.domain && answer == other.answer }
}

nonisolated struct DNSRewriteSettings: Equatable, Sendable {
    let isEnabled: Bool
    let rewrites: [DNSRewrite]

    func entry(matching rewrite: DNSRewrite) -> DNSRewrite? {
        rewrites.first { $0.matches(rewrite) }
    }
}

nonisolated enum DNSRewriteChange: Equatable, Sendable {
    case setRewritesEnabled(Bool)
    case add(DNSRewrite)
    case update(DNSRewrite, to: DNSRewrite)
    case remove(DNSRewrite)

    func isConfirmed(by settings: DNSRewriteSettings) -> Bool {
        switch self {
        case let .setRewritesEnabled(isOn):
            settings.isEnabled == isOn
        case let .add(rewrite):
            settings.entry(matching: rewrite) != nil
        case let .update(old, new):
            settings.entry(matching: new)?.isEnabled == new.isEnabled
                && (old.matches(new) || settings.entry(matching: old) == nil)
        case let .remove(rewrite):
            settings.entry(matching: rewrite) == nil
        }
    }
}

/// Validation of rewrite input before anything is sent.
nonisolated enum DNSRewriteInput {
    /// Host name, optionally with a leading "*." wildcard.
    static func normalizedDomain(_ input: String) -> String? {
        let value = input.trimmingCharacters(in: .whitespaces).lowercased()
        let host = value.hasPrefix("*.") ? String(value.dropFirst(2)) : value
        return CustomDomainRules.normalizedDomain(host) == host ? value : nil
    }

    /// IPv4/IPv6 address, host name, or "A"/"AAAA" (keep the upstream records).
    static func normalizedAnswer(_ input: String) -> String? {
        let value = input.trimmingCharacters(in: .whitespaces)
        if value == "A" || value == "AAAA" { return value }
        if IPv4Address(value) != nil || IPv6Address(value) != nil { return value }
        // Digits and dots only must be a valid IPv4 address, not a host name.
        if value.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") }) { return nil }
        return CustomDomainRules.normalizedDomain(value)
    }

    static func rewrite(domain: String, answer: String, isEnabled: Bool = true) -> DNSRewrite? {
        guard let domain = normalizedDomain(domain), let answer = normalizedAnswer(answer) else { return nil }
        return DNSRewrite(domain: domain, answer: answer, isEnabled: isEnabled)
    }
}

/// Applies rewrite changes and confirms them by reading the list back.
nonisolated struct DNSRewriteUpdater: Sendable {
    let repository: any AdGuardRepository

    func apply(_ change: DNSRewriteChange, current: DNSRewriteSettings) async throws(APIError) -> DNSRewriteSettings {
        if case let .add(rewrite) = change, current.entry(matching: rewrite) != nil { throw .invalidInput }
        try await repository.updateRewrites(change)
        let settings = try await repository.fetchRewrites()
        guard change.isConfirmed(by: settings) else { throw .changeNotConfirmed }
        return settings
    }
}
