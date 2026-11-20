import Foundation

/// State of AdGuard Home's DNS filtering. This is the "protection" switch in
/// AdGuard Home and is distinct from the DNS server itself running or not.
nonisolated enum FilteringState: Equatable, Sendable {
    case enabled
    case disabled
    case paused(until: Date)
}

/// Domain model of the AdGuard Home server status.
nonisolated struct ServerStatus: Equatable, Sendable {
    /// Installed version, e.g. "v0.107.57"; `nil` if not reported.
    let version: String?
    /// Whether the DNS server is running.
    let isDNSRunning: Bool
    let filtering: FilteringState
    let dnsAddresses: [String]
    let dnsPort: Int?
    let startedAt: Date?
}

nonisolated enum ServerStatusMapper {
    static func map(_ dto: ServerStatusDTO, now: Date) -> ServerStatus {
        ServerStatus(
            version: dto.version.flatMap { $0.isEmpty ? nil : $0 },
            isDNSRunning: dto.running ?? false,
            filtering: filteringState(from: dto, now: now),
            dnsAddresses: dto.dnsAddresses ?? [],
            dnsPort: dto.dnsPort,
            startedAt: dto.startTime.map { Date(timeIntervalSince1970: $0 / 1000) }
        )
    }

    private static func filteringState(from dto: ServerStatusDTO, now: Date) -> FilteringState {
        if dto.protectionEnabled == true { return .enabled }
        if let remaining = dto.protectionDisabledDuration, remaining > 0 {
            return .paused(until: now.addingTimeInterval(TimeInterval(remaining) / 1000))
        }
        return .disabled
    }
}
