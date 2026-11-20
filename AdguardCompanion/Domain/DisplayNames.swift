import Foundation

/// A domain split for display: the subdomain part can be de-emphasized and
/// truncated while the registrable domain stays readable.
nonisolated struct DomainDisplayParts: Equatable, Sendable {
    /// e.g. "browser-intake." for "browser-intake.datadoghq.com".
    /// Includes the trailing dot; empty if there is no subdomain.
    let prefix: String
    /// e.g. "datadoghq.com" or "bbc.co.uk".
    let base: String

    /// Common two-level public suffixes. Not a full public suffix list, which
    /// would be a large dependency for a purely cosmetic split.
    private static let twoLevelSuffixes: Set<String> = [
        "co.uk", "org.uk", "ac.uk", "gov.uk", "com.au", "net.au", "org.au", "co.nz", "co.jp",
        "ne.jp", "or.jp", "com.br", "com.cn", "com.tr", "co.za", "co.in", "co.kr", "com.mx",
    ]

    init(prefix: String, base: String) {
        self.prefix = prefix
        self.base = base
    }

    init(domain: String) {
        let labels = domain.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard labels.count > 2 else {
            self.init(prefix: "", base: domain)
            return
        }
        let lastTwo = labels.suffix(2).joined(separator: ".")
        let baseCount = Self.twoLevelSuffixes.contains(lastTwo) && labels.count > 3 ? 3 : 2
        let base = labels.suffix(baseCount).joined(separator: ".")
        let prefix = labels.dropLast(baseCount).joined(separator: ".") + "."
        self.init(prefix: prefix, base: base)
    }

    /// The domain with invisible break opportunities after each dot, so long
    /// names wrap at label boundaries instead of being hyphenated mid-label.
    /// For display only: never copy or send this string.
    static func wrappable(_ domain: String) -> String {
        domain.replacingOccurrences(of: ".", with: ".\u{200B}")
    }
}

nonisolated enum DeviceName {
    /// Local DNS suffixes added by home routers that carry no information.
    static let localSuffixes = [".fritz.box", ".home.arpa", ".localdomain", ".local", ".lan", ".home", ".internal"]

    /// Human-readable device name, or `nil` if the name is missing or only a
    /// machine identifier (e.g. a long hexadecimal ClientID).
    static func readable(_ name: String?) -> String? {
        guard var name, !name.isEmpty else { return nil }
        for suffix in localSuffixes where name.lowercased().hasSuffix(suffix) && name.count > suffix.count {
            name.removeLast(suffix.count)
            break
        }
        return looksLikeIdentifier(name) ? nil : name
    }

    /// `true` for strings like "20c62acf47c34bc0b6ee631c2b590712".
    static func looksLikeIdentifier(_ value: String) -> Bool {
        let hex = value.filter { $0 != "-" }
        return hex.count >= 16 && hex.allSatisfy(\.isHexDigit)
    }
}
