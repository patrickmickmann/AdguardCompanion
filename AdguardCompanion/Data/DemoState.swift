import Foundation
import Synchronization

/// DEMO DATA ONLY. Shared, lock-protected storage for the demo's user rules.
final class DemoUserRules: Sendable {
    private let rules = Mutex<[String]>([
        "! Demo-Regeln",
        "||tracking.example.net^$important",
        "@@||app-measurement.com^$important",
    ])

    func current() -> [String] { rules.withLock { $0 } }
    func replace(with newRules: [String]) { rules.withLock { $0 = newRules } }
}

/// DEMO DATA ONLY. Lock-protected protection switches; a pause is stored as
/// its end date and reported as enabled again once it has passed.
final class DemoProtection: Sendable {
    private let settings = Mutex(ProtectionSettings(
        protection: .enabled, safeBrowsing: true, parentalControl: false, safeSearch: false
    ))

    func current() -> ProtectionSettings {
        settings.withLock { settings in
            if case let .paused(until) = settings.protection, until <= .now {
                settings.protection = .enabled
            }
            return settings
        }
    }

    func apply(_ change: ProtectionChange) {
        settings.withLock { settings in
            switch change {
            case .enableProtection: settings.protection = .enabled
            case let .pauseProtection(pause): settings.protection = .paused(until: .now + pause.duration.timeInterval)
            case .disableProtection: settings.protection = .disabled
            case let .safeBrowsing(isOn): settings.safeBrowsing = isOn
            case let .parentalControl(isOn): settings.parentalControl = isOn
            case let .safeSearch(isOn): settings.safeSearch = isOn
            }
        }
    }
}

/// DEMO DATA ONLY. Lock-protected filter list subscriptions.
final class DemoFilterLists: Sendable {
    private let settings: Mutex<FilterListSettings>

    init(initial: FilterListSettings = DemoFilterLists.sample) {
        settings = Mutex(initial)
    }

    static let sample = FilterListSettings(
        isFilteringEnabled: true, updateIntervalHours: 24,
        lists: [
            FilterList(id: 1, name: "AdGuard DNS filter",
                       url: "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt",
                       kind: .blocklist, isEnabled: true, ruleCount: 74_812,
                       lastUpdated: .now.addingTimeInterval(-3 * 3600)),
            FilterList(id: 2, name: "AdAway Default Blocklist",
                       url: "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt",
                       kind: .blocklist, isEnabled: false, ruleCount: 6_540,
                       lastUpdated: .now.addingTimeInterval(-26 * 3600)),
            FilterList(id: 3, name: "Eigene Ausnahmen", url: "https://example.org/allowlist.txt",
                       kind: .allowlist, isEnabled: true, ruleCount: 12,
                       lastUpdated: .now.addingTimeInterval(-3 * 3600)),
        ]
    )

    func current() -> FilterListSettings { settings.withLock { $0 } }

    func apply(_ change: FilterListChange) {
        settings.withLock { settings in
            var lists = settings.lists
            var isFilteringEnabled = settings.isFilteringEnabled
            switch change {
            case let .setFilteringEnabled(isOn):
                isFilteringEnabled = isOn
            case let .setEnabled(list, isOn):
                lists = lists.map { $0.id == list.id ? $0.with(isEnabled: isOn) : $0 }
            case let .add(name, url, kind):
                let id = (lists.map(\.id).max() ?? 0) + 1
                lists.append(FilterList(id: id, name: name, url: url, kind: kind, isEnabled: true,
                                        ruleCount: 1_000, lastUpdated: .now))
            case let .remove(list):
                lists.removeAll { $0.id == list.id }
            }
            settings = FilterListSettings(isFilteringEnabled: isFilteringEnabled,
                                          updateIntervalHours: settings.updateIntervalHours, lists: lists)
        }
    }
}
