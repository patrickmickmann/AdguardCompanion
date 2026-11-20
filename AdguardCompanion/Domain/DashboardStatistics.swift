import Foundation

/// Time window covered by AdGuard Home statistics.
nonisolated struct StatisticsPeriod: Equatable, Sendable {
    enum Unit: Equatable, Sendable { case hour, day }

    let unit: Unit
    /// Number of units, e.g. 24 hours or 7 days.
    let length: Int

    var localizedDescription: String {
        switch unit {
        case .hour: length == 1 ? "Letzte Stunde" : "Letzte \(length) Stunden"
        case .day: length == 1 ? "Letzter Tag" : "Letzte \(length) Tage"
        }
    }
}

/// Requests blocked by the individual AdGuard Home modules.
nonisolated struct BlockedBreakdown: Equatable, Sendable {
    let filtering: Int
    let safeBrowsing: Int
    let parentalControl: Int

    var total: Int { filtering + safeBrowsing + parentalControl }
}

/// One time slot of the traffic chart.
nonisolated struct TrafficBucket: Identifiable, Equatable, Sendable {
    let start: Date
    let allowed: Int
    let blocked: Int

    var id: Date { start }
    var total: Int { allowed + blocked }
}

/// A ranked domain or client with its request count.
nonisolated struct RankedEntry: Identifiable, Equatable, Sendable {
    let name: String
    let count: Int

    var id: String { name }
}

/// Dashboard statistics. Optional values are `nil` when the server did not
/// report them; they must never be shown as zero.
nonisolated struct DashboardStatistics: Equatable, Sendable {
    let period: StatisticsPeriod
    let totalQueries: Int?
    let blocked: BlockedBreakdown?
    let averageResponseTime: Duration?
    let traffic: [TrafficBucket]
    let topQueriedDomains: [RankedEntry]
    let topBlockedDomains: [RankedEntry]
    let topClients: [RankedEntry]

    /// Share of blocked requests in `0...1`, or `nil` if not computable.
    var blockRatio: Double? {
        guard let totalQueries, let blocked, totalQueries > 0 else { return nil }
        return Double(blocked.total) / Double(totalQueries)
    }

    var hasTraffic: Bool { traffic.contains { $0.total > 0 } }
}
