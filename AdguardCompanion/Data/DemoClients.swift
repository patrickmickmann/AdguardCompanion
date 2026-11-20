import Foundation

/// DEMO DATA ONLY. Sample clients matching the demo statistics' top clients.
nonisolated enum DemoClients {
    static let serviceNames = ["youtube": "YouTube", "tiktok": "TikTok", "instagram": "Instagram"]

    static let clients = ClientsDTO(
        clients: [
            PersistentClientDTO(
                name: "Kinder-iPad", ids: ["192.168.1.23"], useGlobalSettings: false,
                filteringEnabled: true, parentalEnabled: true, safebrowsingEnabled: true,
                safeSearch: SafeSearchConfigDTO(enabled: true), useGlobalBlockedServices: false,
                blockedServices: ["tiktok", "instagram"], upstreams: [], tags: ["device_tablet", "user_child"],
                ignoreQuerylog: false, ignoreStatistics: false
            ),
            PersistentClientDTO(
                name: "MacBook Pro", ids: ["192.168.1.10", "a4:83:e7:12:34:56"], useGlobalSettings: true,
                filteringEnabled: true, parentalEnabled: false, safebrowsingEnabled: true,
                safeSearch: SafeSearchConfigDTO(enabled: false), useGlobalBlockedServices: true,
                blockedServices: [], upstreams: ["https://dns.quad9.net/dns-query"], tags: ["device_laptop"],
                ignoreQuerylog: false, ignoreStatistics: false
            ),
        ],
        autoClients: [
            RuntimeClientDTO(ip: "192.168.1.12", name: "iPhone.fritz.box", source: "rDNS", whoisInfo: nil),
            RuntimeClientDTO(ip: "192.168.1.30", name: "Apple-TV.fritz.box", source: "rDNS", whoisInfo: nil),
            RuntimeClientDTO(ip: "192.168.1.45", name: "", source: "ARP", whoisInfo: nil),
            RuntimeClientDTO(ip: "192.168.1.60", name: "drucker", source: "DHCP", whoisInfo: nil),
        ]
    )
}
