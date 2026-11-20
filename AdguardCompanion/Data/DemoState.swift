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
