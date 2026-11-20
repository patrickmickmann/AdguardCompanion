import Foundation
import Testing
@testable import AdguardCompanion

struct StatisticsMapperTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    /// 2026-01-15 10:30 UTC
    private let now = Date(timeIntervalSince1970: 1_768_473_000)

    private func stats(
        total: Int? = 100,
        blocked: Int? = 20,
        safeBrowsing: Int? = 3,
        parental: Int? = 2,
        avg: Double? = 0.012,
        queries: [Int]? = [10, 20, 30],
        blockedSeries: [Int]? = [1, 2, 3]
    ) -> StatsDTO {
        StatsDTO(
            timeUnits: "hours", numDnsQueries: total, numBlockedFiltering: blocked,
            numReplacedSafebrowsing: safeBrowsing, numReplacedSafesearch: 7, numReplacedParental: parental,
            avgProcessingTime: avg,
            topQueriedDomains: [["a.example": 5], ["b.example": 3]],
            topClients: [["192.168.1.2": 9]], topBlockedDomains: [],
            dnsQueries: queries, blockedFiltering: blockedSeries,
            replacedSafebrowsing: [0, 1, 0], replacedParental: nil
        )
    }

    @Test func blockedTotalSumsBlockingModulesButNotSafeSearch() {
        let result = StatisticsMapper.map(stats(), now: now, calendar: calendar)
        #expect(result.blocked?.total == 25)
        #expect(result.blockRatio == 0.25)
    }

    @Test func missingValuesStayNilInsteadOfZero() {
        let result = StatisticsMapper.map(stats(total: nil, blocked: nil, avg: nil), now: now, calendar: calendar)
        #expect(result.totalQueries == nil)
        #expect(result.blocked == nil)
        #expect(result.blockRatio == nil)
        #expect(result.averageResponseTime == nil)
    }

    @Test func blockRatioIsNilWithoutQueries() {
        let result = StatisticsMapper.map(stats(total: 0, blocked: 0, safeBrowsing: 0, parental: 0), now: now, calendar: calendar)
        #expect(result.blockRatio == nil)
        #expect(result.averageResponseTime == nil)
    }

    @Test func averageResponseTimeConvertsSecondsToMilliseconds() {
        let result = StatisticsMapper.map(stats(avg: 0.012), now: now, calendar: calendar)
        #expect(result.averageResponseTime == .milliseconds(12))
    }

    @Test func trafficEndsWithCurrentHourAndSplitsAllowedAndBlocked() throws {
        let result = StatisticsMapper.map(stats(), now: now, calendar: calendar)
        #expect(result.period == StatisticsPeriod(unit: .hour, length: 3))
        #expect(result.traffic.map(\.blocked) == [1, 3, 3])
        #expect(result.traffic.map(\.allowed) == [9, 17, 27])

        let last = try #require(result.traffic.last)
        #expect(last.start == Date(timeIntervalSince1970: 1_768_471_200)) // 10:00 UTC
        let first = try #require(result.traffic.first)
        #expect(first.start == last.start.addingTimeInterval(-2 * 3600))
    }

    @Test func blockedNeverExceedsQueriesInBucket() {
        let result = StatisticsMapper.map(stats(queries: [2], blockedSeries: [5]), now: now, calendar: calendar)
        #expect(result.traffic.first?.blocked == 2)
        #expect(result.traffic.first?.allowed == 0)
    }

    @Test func dailyUnitsProduceDayPeriod() {
        let dto = StatsDTO(
            timeUnits: "days", numDnsQueries: 1, numBlockedFiltering: 0, numReplacedSafebrowsing: nil,
            numReplacedSafesearch: nil, numReplacedParental: nil, avgProcessingTime: nil,
            topQueriedDomains: nil, topClients: nil, topBlockedDomains: nil,
            dnsQueries: Array(repeating: 1, count: 7), blockedFiltering: nil,
            replacedSafebrowsing: nil, replacedParental: nil
        )
        let result = StatisticsMapper.map(dto, now: now, calendar: calendar)
        #expect(result.period.localizedDescription == "Letzte 7 Tage")
        #expect(result.traffic.count == 7)
    }

    @Test func rankedEntriesKeepOrderAndSkipEmptyNames() {
        let entries = StatisticsMapper.ranked([["x.example": 4], [:], ["": 2], ["y.example": 1.0]])
        #expect(entries == [RankedEntry(name: "x.example", count: 4), RankedEntry(name: "y.example", count: 1)])
    }

    @Test func decodesRealPayloadShape() throws {
        let json = Data("""
        {"time_units":"hours","num_dns_queries":5,"num_blocked_filtering":1,
         "avg_processing_time":0.5,"top_clients":[{"10.0.0.1":5}],"dns_queries":[2,3],
         "blocked_filtering":[0,1],"unknown_future_field":true}
        """.utf8)
        let dto = try JSONDecoder.adGuard.decode(StatsDTO.self, from: json)
        let result = StatisticsMapper.map(dto, now: now, calendar: calendar)
        #expect(result.totalQueries == 5)
        #expect(result.topClients.first?.name == "10.0.0.1")
        #expect(result.traffic.count == 2)
    }
}
