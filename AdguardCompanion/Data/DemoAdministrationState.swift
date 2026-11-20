import Foundation
import Synchronization

/// DEMO DATA ONLY. Lock-protected DNS rewrites.
final class DemoRewrites: Sendable {
    private let settings = Mutex(DNSRewriteSettings(isEnabled: true, rewrites: [
        DNSRewrite(domain: "nas.home.arpa", answer: "192.168.1.40", isEnabled: true),
        DNSRewrite(domain: "*.lab.home.arpa", answer: "192.168.1.50", isEnabled: false),
    ]))

    func current() -> DNSRewriteSettings { settings.withLock { $0 } }

    func apply(_ change: DNSRewriteChange) {
        settings.withLock { settings in
            var rewrites = settings.rewrites
            var isEnabled = settings.isEnabled
            switch change {
            case let .setRewritesEnabled(isOn): isEnabled = isOn
            case let .add(rewrite): rewrites.append(rewrite)
            case let .update(old, new): rewrites = rewrites.map { $0.matches(old) ? new : $0 }
            case let .remove(rewrite): rewrites.removeAll { $0.matches(rewrite) }
            }
            settings = DNSRewriteSettings(isEnabled: isEnabled, rewrites: rewrites)
        }
    }
}

/// DEMO DATA ONLY. A small service catalog with lock-protected blocked IDs.
final class DemoBlockedServices: Sendable {
    private static let catalog = [
        BlockableService(id: "youtube", name: "YouTube", groupID: "streaming"),
        BlockableService(id: "netflix", name: "Netflix", groupID: "streaming"),
        BlockableService(id: "tiktok", name: "TikTok", groupID: "social_network"),
        BlockableService(id: "instagram", name: "Instagram", groupID: "social_network"),
        BlockableService(id: "whatsapp", name: "WhatsApp", groupID: "messenger"),
        BlockableService(id: "steam", name: "Steam", groupID: "gaming"),
    ]
    private let blockedIDs = Mutex<Set<String>>(["tiktok"])

    func current() -> BlockedServices {
        BlockedServices(catalog: Self.catalog, blockedIDs: blockedIDs.withLock { $0 },
                        schedule: .object(["time_zone": .string("Local")]))
    }

    func set(_ ids: Set<String>) { blockedIDs.withLock { $0 = ids } }
}

/// DEMO DATA ONLY. Lock-protected query log and statistics configuration.
final class DemoLogSettings: Sendable {
    private let settings = Mutex<[LogKind: LogSettings]>([
        .queryLog: LogSettings(kind: .queryLog, document: [
            "enabled": .bool(true), "interval": .number(7 * 86_400_000), "anonymize_client_ip": .bool(false),
            "ignored": .array([.string("time.apple.com")]), "ignored_enabled": .bool(true),
        ]),
        .statistics: LogSettings(kind: .statistics, document: [
            "enabled": .bool(true), "interval": .number(86_400_000), "ignored": .array([]),
            "ignored_enabled": .bool(true),
        ]),
    ])

    func current(_ kind: LogKind) -> LogSettings {
        settings.withLock { $0[kind] } ?? LogSettings(kind: kind, document: [:])
    }

    func save(_ value: LogSettings) { settings.withLock { $0[value.kind] = value } }
}

/// DEMO DATA ONLY. Lock-protected DNS settings and a fixed TLS status.
final class DemoDNSSettings: Sendable {
    private let document = Mutex<JSONObject>([
        "upstream_dns": .array([.string("https://dns.quad9.net/dns-query"), .string("tls://1.1.1.1")]),
        "bootstrap_dns": .array([.string("9.9.9.9"), .string("1.1.1.1")]),
        "fallback_dns": .array([]),
        "upstream_mode": .string("load_balance"), "dnssec_enabled": .bool(true),
        "cache_enabled": .bool(true), "cache_optimistic": .bool(false), "cache_size": .number(4_194_304),
        "disable_ipv6": .bool(false), "ratelimit": .number(20), "blocking_mode": .string("default"),
    ])

    static let tls = TLSStatus(document: [
        "enabled": .bool(false), "force_https": .bool(false), "valid_cert": .bool(false),
    ])

    func current() -> DNSSettings { DNSSettings(document: document.withLock { $0 }) }

    func apply(_ patch: JSONObject) { document.withLock { $0.merge(patch) { _, new in new } } }
}
