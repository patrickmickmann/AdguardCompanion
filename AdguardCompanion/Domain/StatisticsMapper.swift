import Foundation

/// Maps the `/control/stats` payload to `DashboardStatistics`.
nonisolated enum StatisticsMapper {
    static func map(_ dto: StatsDTO, now: Date, calendar: Calendar) -> DashboardStatistics {
        let unit: StatisticsPeriod.Unit = dto.timeUnits == "days" ? .day : .hour
        let queries = dto.dnsQueries ?? []
        let fallbackLength = unit == .hour ? 24 : 1

        return DashboardStatistics(
            period: StatisticsPeriod(unit: unit, length: queries.isEmpty ? fallbackLength : queries.count),
            totalQueries: dto.numDnsQueries,
            blocked: blockedBreakdown(from: dto),
            averageResponseTime: averageResponseTime(from: dto),
            traffic: traffic(from: dto, unit: unit, now: now, calendar: calendar),
            topQueriedDomains: ranked(dto.topQueriedDomains),
            topBlockedDomains: ranked(dto.topBlockedDomains),
            topClients: ranked(dto.topClients)
        )
    }

    private static func blockedBreakdown(from dto: StatsDTO) -> BlockedBreakdown? {
        guard let filtering = dto.numBlockedFiltering else { return nil }
        return BlockedBreakdown(
            filtering: filtering,
            safeBrowsing: dto.numReplacedSafebrowsing ?? 0,
            parentalControl: dto.numReplacedParental ?? 0
        )
    }

    /// Only meaningful when requests were actually processed.
    private static func averageResponseTime(from dto: StatsDTO) -> Duration? {
        guard let seconds = dto.avgProcessingTime, seconds > 0, (dto.numDnsQueries ?? 0) > 0 else {
            return nil
        }
        return .milliseconds(seconds * 1000)
    }

    /// Builds chart buckets. AdGuard Home returns the series oldest first,
    /// with the last element representing the current hour or day.
    static func traffic(
        from dto: StatsDTO,
        unit: StatisticsPeriod.Unit,
        now: Date,
        calendar: Calendar
    ) -> [TrafficBucket] {
        let queries = dto.dnsQueries ?? []
        guard !queries.isEmpty else { return [] }
        let component: Calendar.Component = unit == .hour ? .hour : .day
        let currentStart = calendar.dateInterval(of: component, for: now)?.start ?? now

        return queries.indices.compactMap { index in
            let offset = index - (queries.count - 1)
            guard let start = calendar.date(byAdding: component, value: offset, to: currentStart) else {
                return nil
            }
            let blocked = value(dto.blockedFiltering, at: index)
                + value(dto.replacedSafebrowsing, at: index)
                + value(dto.replacedParental, at: index)
            let clampedBlocked = min(blocked, queries[index])
            return TrafficBucket(start: start, allowed: queries[index] - clampedBlocked, blocked: clampedBlocked)
        }
    }

    static func ranked(_ entries: [[String: Double]]?) -> [RankedEntry] {
        (entries ?? []).compactMap { entry in
            guard let (name, count) = entry.first, !name.isEmpty else { return nil }
            return RankedEntry(name: name, count: Int(count))
        }
    }

    private static func value(_ series: [Int]?, at index: Int) -> Int {
        guard let series, series.indices.contains(index) else { return 0 }
        return series[index]
    }
}
