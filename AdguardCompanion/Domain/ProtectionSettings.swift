import Foundation

/// Server-wide protection switches as reported by AdGuard Home.
nonisolated struct ProtectionSettings: Equatable, Sendable {
    /// The global protection switch (`/control/protection`).
    var protection: FilteringState
    var safeBrowsing: Bool
    var parentalControl: Bool
    var safeSearch: Bool
}

/// A pause length offered for the global protection switch.
nonisolated enum ProtectionPause: CaseIterable, Sendable {
    case oneMinute, tenMinutes, oneHour, eightHours, oneDay

    var duration: Duration {
        switch self {
        case .oneMinute: .seconds(60)
        case .tenMinutes: .seconds(10 * 60)
        case .oneHour: .seconds(60 * 60)
        case .eightHours: .seconds(8 * 60 * 60)
        case .oneDay: .seconds(24 * 60 * 60)
        }
    }

    var milliseconds: Int64 { Int64(duration.components.seconds) * 1000 }
}

/// One change to the protection settings.
nonisolated enum ProtectionChange: Equatable, Sendable {
    case enableProtection
    case pauseProtection(ProtectionPause)
    case disableProtection
    case safeBrowsing(Bool)
    case parentalControl(Bool)
    case safeSearch(Bool)

    /// Whether settings read back from the server show this change.
    func isConfirmed(by settings: ProtectionSettings) -> Bool {
        switch self {
        case .enableProtection: settings.protection == .enabled
        case .pauseProtection:
            if case .paused = settings.protection { true } else { false }
        case .disableProtection: settings.protection == .disabled
        case let .safeBrowsing(isOn): settings.safeBrowsing == isOn
        case let .parentalControl(isOn): settings.parentalControl == isOn
        case let .safeSearch(isOn): settings.safeSearch == isOn
        }
    }
}

/// Applies a protection change and reports success only after reading the
/// settings back from the server.
nonisolated struct ProtectionUpdater: Sendable {
    let repository: any AdGuardRepository

    func apply(_ change: ProtectionChange) async throws(APIError) -> ProtectionSettings {
        try await repository.updateProtection(change)
        let settings = try await repository.fetchProtectionSettings()
        guard change.isConfirmed(by: settings) else { throw .changeNotConfirmed }
        return settings
    }
}
