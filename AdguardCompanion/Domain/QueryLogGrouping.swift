import Foundation

/// Queries a device sent together for the same domain, typically A + AAAA
/// (+ HTTPS) within the same second. Shown as one row.
nonisolated struct QueryLogGroup: Identifiable, Equatable, Sendable {
    /// Newest first, as delivered by the server. Never empty.
    let entries: [QueryLogEntry]

    var primary: QueryLogEntry { entries[0] }
    var id: String { primary.id }
    var date: Date { primary.date }

    /// Distinct record types in a stable order (A, AAAA, HTTPS, then alphabetical),
    /// so rows read the same regardless of which query arrived first.
    var queryTypes: [String] {
        let preferred = ["A", "AAAA", "HTTPS"]
        return Set(entries.compactMap(\.queryType)).sorted { lhs, rhs in
            let left = preferred.firstIndex(of: lhs) ?? preferred.count
            let right = preferred.firstIndex(of: rhs) ?? preferred.count
            return left == right ? lhs < rhs : left < right
        }
    }
}

/// One minute of activity, used as a list section.
nonisolated struct QueryLogSection: Identifiable, Equatable, Sendable {
    let minute: Date
    let groups: [QueryLogGroup]

    var id: Date { minute }
}

nonisolated enum QueryLogGrouping {
    /// Maximum time between queries that are still considered one request.
    static let window: TimeInterval = 2

    /// Merges adjacent entries with the same domain, client and outcome.
    static func groups(from entries: [QueryLogEntry]) -> [QueryLogGroup] {
        var result: [[QueryLogEntry]] = []
        for entry in entries {
            if let first = result.last?.first, belongTogether(first, entry) {
                result[result.count - 1].append(entry)
            } else {
                result.append([entry])
            }
        }
        return result.map(QueryLogGroup.init(entries:))
    }

    /// Splits groups into per-minute sections, newest first.
    static func sections(from groups: [QueryLogGroup], calendar: Calendar) -> [QueryLogSection] {
        var sections: [QueryLogSection] = []
        var current: (minute: Date, groups: [QueryLogGroup])?
        for group in groups {
            let minute = calendar.dateInterval(of: .minute, for: group.date)?.start ?? group.date
            if current?.minute == minute {
                current?.groups.append(group)
            } else {
                if let finished = current { sections.append(QueryLogSection(minute: finished.minute, groups: finished.groups)) }
                current = (minute, [group])
            }
        }
        if let finished = current { sections.append(QueryLogSection(minute: finished.minute, groups: finished.groups)) }
        return sections
    }

    private static func belongTogether(_ lhs: QueryLogEntry, _ rhs: QueryLogEntry) -> Bool {
        lhs.domain == rhs.domain
            && lhs.client.deviceKey == rhs.client.deviceKey
            && lhs.outcome == rhs.outcome
            && abs(lhs.date.timeIntervalSince(rhs.date)) <= window
    }
}
