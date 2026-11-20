import Foundation
import Testing
@testable import AdguardCompanion

struct TrafficSelectionTests {
    private let start = Date(timeIntervalSince1970: 1_768_471_200)

    private func statistics(_ totals: [Int]) -> DashboardStatistics {
        DashboardStatistics(
            period: StatisticsPeriod(unit: .hour, length: totals.count),
            totalQueries: totals.reduce(0, +), blocked: nil, averageResponseTime: nil,
            traffic: totals.enumerated().map { index, total in
                TrafficBucket(start: start.addingTimeInterval(Double(index) * 3600), allowed: total, blocked: 0)
            },
            topQueriedDomains: [], topBlockedDomains: [], topClients: []
        )
    }

    @Test func bucketContainingMidHourDate() {
        let stats = statistics([10, 20, 30])
        let bucket = stats.bucket(containing: start.addingTimeInterval(3600 + 1_800))
        #expect(bucket?.total == 20)
    }

    @Test func dateBeforeFirstBucketSelectsNothing() {
        #expect(statistics([10]).bucket(containing: start.addingTimeInterval(-1)) == nil)
    }

    @Test func dateAfterLastBucketSelectsLast() {
        #expect(statistics([10, 20]).bucket(containing: start.addingTimeInterval(10 * 3600))?.total == 20)
    }

    @Test func durationMilliseconds() {
        #expect(Duration.milliseconds(14).milliseconds == 14)
        #expect(Duration.seconds(1.5).formattedMilliseconds == 1_500.formatted())
    }

    @Test func averagePerBucket() {
        #expect(statistics([10, 20, 30]).averageQueriesPerBucket == 20)
        #expect(statistics([]).averageQueriesPerBucket == nil)
    }
}

@MainActor
struct ProtectionSummaryTests {
    private func status(running: Bool = true, filtering: FilteringState = .enabled) -> ServerStatus {
        ServerStatus(version: "v1", isDNSRunning: running, filtering: filtering,
                     dnsAddresses: [], dnsPort: nil, startedAt: nil)
    }

    @Test func protectedWhenRunningAndFiltering() {
        #expect(ProtectionSummary(status: status(), isReachable: true) == .protected)
    }

    @Test func unreachableWinsOverEverything() {
        #expect(ProtectionSummary(status: status(), isReachable: false) == .unreachable)
    }

    @Test func stoppedDNSWinsOverFiltering() {
        #expect(ProtectionSummary(status: status(running: false), isReachable: true) == .dnsStopped)
    }

    @Test func pausedAndDisabledFiltering() {
        let until = Date(timeIntervalSince1970: 100)
        #expect(ProtectionSummary(status: status(filtering: .paused(until: until)), isReachable: true)
                == .paused(until: until))
        #expect(ProtectionSummary(status: status(filtering: .disabled), isReachable: true) == .filteringDisabled)
        #expect(ProtectionSummary.filteringDisabled.tone == .warning)
    }
}
