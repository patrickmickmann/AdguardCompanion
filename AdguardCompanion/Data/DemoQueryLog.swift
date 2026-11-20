import Foundation

/// DEMO DATA ONLY. Deterministic sample query log that supports the same
/// search, filter and paging behavior as the real endpoint.
nonisolated enum DemoQueryLog {
    private struct Sample {
        let domain: String
        let type: String
        let reason: String
        let rule: String?
        let listID: Int?
    }

    private static let samples: [Sample] = [
        Sample(domain: "www.apple.com", type: "HTTPS", reason: "NotFilteredNotFound", rule: nil, listID: nil),
        Sample(domain: "doubleclick.net", type: "A", reason: "FilteredBlackList", rule: "||doubleclick.net^", listID: 1),
        Sample(domain: "api.github.com", type: "AAAA", reason: "NotFilteredNotFound", rule: nil, listID: nil),
        Sample(domain: "ads.google.com", type: "A", reason: "FilteredBlackList", rule: "||ads.google.com^", listID: 1),
        Sample(domain: "nas.local", type: "A", reason: "Rewrite", rule: nil, listID: nil),
        Sample(domain: "icloud.com", type: "HTTPS", reason: "NotFilteredWhiteList", rule: "@@||icloud.com^", listID: 0),
        Sample(domain: "telemetry.microsoft.com", type: "A", reason: "FilteredBlackList",
               rule: "||telemetry.microsoft.com^", listID: 2),
        Sample(domain: "www.google.com", type: "A", reason: "FilteredSafeSearch", rule: nil, listID: nil),
    ]

    private static let clients: [(address: String, name: String?)] = [
        ("192.168.1.12", "iPhone"), ("192.168.1.10", "MacBook Pro"),
        ("192.168.1.23", "Apple TV"), ("192.168.1.45", nil),
    ]

    static let entryCount = 120
    static let catalog = FilterListCatalog(names: [1: "AdGuard DNS filter", 2: "AdAway Default Blocklist"])

    static func page(for query: QueryLogQuery, now: Date) -> QueryLogPage {
        let matching = allItems(now: now).filter { matches($0, query: query) }
        let start = query.cursor.flatMap(Int.init) ?? 0
        let slice = Array(matching.dropFirst(start).prefix(query.limit))
        let end = start + slice.count
        let entries = slice.enumerated().compactMap { offset, item in
            QueryLogMapper.entry(from: item, index: start + offset)
        }
        return QueryLogPage(entries: entries, nextCursor: end < matching.count ? String(end) : nil)
    }

    private static func allItems(now: Date) -> [QueryLogItemDTO] {
        (0..<entryCount).map { index in
            let sample = samples[index % samples.count]
            let client = clients[index % clients.count]
            let time = now.addingTimeInterval(-Double(index) * 41)
            let isRewrite = sample.reason == "Rewrite"
            return QueryLogItemDTO(
                answer: sample.reason.hasPrefix("Filtered") && sample.reason != "FilteredSafeSearch"
                    ? [] : [DNSAnswerDTO(ttl: 300, type: "A", value: isRewrite ? "192.168.1.20" : "17.253.144.10")],
                cached: index % 3 == 0, upstream: isRewrite ? nil : "https://dns.quad9.net:443/dns-query",
                answerDnssec: false, client: client.address,
                clientInfo: QueryLogClientDTO(name: client.name, whois: nil), clientProto: "",
                elapsedMs: String(0.08 + Double(index % 9) * 3.7),
                question: DNSQuestionDTO(class: "IN", name: sample.domain, unicodeName: nil, type: sample.type),
                rules: sample.rule.map { [ResultRuleDTO(filterListId: sample.listID, text: $0)] } ?? [],
                reason: sample.reason, serviceName: nil, status: "NOERROR",
                time: time.formatted(.iso8601)
            )
        }
    }

    private static func matches(_ item: QueryLogItemDTO, query: QueryLogQuery) -> Bool {
        let reasons = query.filter.reasons
        if !reasons.isEmpty, !reasons.contains(item.reason ?? "") { return false }
        let term = query.trimmedSearch.lowercased()
        guard !term.isEmpty else { return true }
        return [item.question?.name, item.client, item.clientInfo?.name]
            .compactMap { $0?.lowercased() }
            .contains { $0.contains(term) }
    }
}
