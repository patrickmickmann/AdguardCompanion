import Foundation

/// Maps `/control/querylog` responses to domain models.
nonisolated enum QueryLogMapper {
    static func map(_ dto: QueryLogDTO, requestedLimit: Int) -> QueryLogPage {
        let items = dto.data ?? []
        let entries = items.enumerated().compactMap { index, item in
            entry(from: item, index: index)
        }
        // A short page means the end of the log; otherwise continue from `oldest`.
        let isLastPage = items.count < requestedLimit
        let cursor = dto.oldest.flatMap { $0.isEmpty ? nil : $0 }
        return QueryLogPage(entries: entries, nextCursor: isLastPage ? nil : cursor)
    }

    /// Returns `nil` for items without a timestamp or domain, which cannot be shown meaningfully.
    static func entry(from item: QueryLogItemDTO, index: Int) -> QueryLogEntry? {
        guard let rawTime = item.time, let date = parseDate(rawTime),
              let domain = nonEmpty(item.question?.unicodeName) ?? nonEmpty(item.question?.name)
        else { return nil }

        let client = QueryClient(
            address: item.client ?? "",
            name: nonEmpty(item.clientInfo?.name),
            organization: nonEmpty(item.clientInfo?.whois?.orgname)
        )
        return QueryLogEntry(
            id: "\(rawTime)#\(index)#\(domain)",
            date: date,
            domain: domain,
            queryType: nonEmpty(item.question?.type),
            client: client,
            outcome: QueryOutcome(reason: item.reason),
            rules: (item.rules ?? []).compactMap { rule in
                nonEmpty(rule.text).map { AppliedRule(text: $0, filterListID: rule.filterListId) }
            },
            serviceName: nonEmpty(item.serviceName),
            responseStatus: nonEmpty(item.status),
            answers: (item.answer ?? []).map {
                DNSAnswerRecord(type: $0.type ?? "", value: $0.value ?? "", ttl: $0.ttl)
            },
            upstream: nonEmpty(item.upstream),
            isCached: item.cached ?? false,
            isDNSSECAuthenticated: item.answerDnssec ?? false,
            elapsed: item.elapsedMs.flatMap(Double.init).map { .nanoseconds(Int64($0 * 1_000_000)) },
            clientProtocol: nonEmpty(item.clientProto)
        )
    }

    /// Parses RFC 3339 timestamps with up to nanosecond precision.
    static func parseDate(_ string: String) -> Date? {
        let normalized = truncatingFraction(of: string)
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(normalized) {
            return date
        }
        return try? Date.ISO8601FormatStyle().parse(normalized)
    }

    /// Reduces fractional seconds to milliseconds, which Foundation parses reliably.
    private static func truncatingFraction(of string: String) -> String {
        guard let dot = string.firstIndex(of: ".") else { return string }
        let fractionStart = string.index(after: dot)
        let fractionEnd = string[fractionStart...].firstIndex { !$0.isNumber } ?? string.endIndex
        let digits = string[fractionStart..<fractionEnd]
        let millis = String(digits.prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
        return String(string[..<fractionStart]) + millis + String(string[fractionEnd...])
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
