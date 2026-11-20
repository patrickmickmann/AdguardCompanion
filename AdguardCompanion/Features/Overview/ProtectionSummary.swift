import Foundation

/// The single most important state of the network, derived from server status
/// and reachability. Ordered by severity: reachability beats DNS beats filtering.
nonisolated enum ProtectionSummary: Equatable {
    case protected
    case paused(until: Date)
    case filteringDisabled
    case dnsStopped
    case unreachable

    init(status: ServerStatus, isReachable: Bool) {
        if !isReachable {
            self = .unreachable
        } else if !status.isDNSRunning {
            self = .dnsStopped
        } else {
            switch status.filtering {
            case .enabled: self = .protected
            case let .paused(until): self = .paused(until: until)
            case .disabled: self = .filteringDisabled
            }
        }
    }

    var title: String {
        switch self {
        case .protected: "Geschützt"
        case .paused: "Schutz pausiert"
        case .filteringDisabled: "Filterung aus"
        case .dnsStopped: "DNS-Server gestoppt"
        case .unreachable: "Nicht erreichbar"
        }
    }

    var detail: String {
        switch self {
        case .protected:
            "DNS-Filterung ist aktiv"
        case let .paused(until):
            "DNS-Filterung pausiert bis \(until.formatted(date: .omitted, time: .shortened))"
        case .filteringDisabled:
            "Anfragen werden nicht gefiltert"
        case .dnsStopped:
            "AdGuard Home beantwortet keine DNS-Anfragen"
        case .unreachable:
            "Angezeigt werden die zuletzt geladenen Daten"
        }
    }

    var systemImage: String {
        switch self {
        case .protected: "checkmark.shield.fill"
        case .paused: "pause.circle.fill"
        case .filteringDisabled: "shield.slash.fill"
        case .dnsStopped: "exclamationmark.shield.fill"
        case .unreachable: "wifi.exclamationmark"
        }
    }

    var tone: StatusTone {
        switch self {
        case .protected: .positive
        case .paused, .filteringDisabled: .warning
        case .dnsStopped, .unreachable: .critical
        }
    }
}
