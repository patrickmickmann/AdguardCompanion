import Foundation

extension LiveAdGuardRepository {
    func fetchProtectionSettings() async throws(APIError) -> ProtectionSettings {
        async let status: ServerStatusDTO = client.get(.status)
        async let safeBrowsing: EnabledStatusDTO = client.get(.safeBrowsingStatus)
        async let parental: EnabledStatusDTO = client.get(.parentalStatus)
        async let safeSearch: SafeSearchSettingsDTO = client.get(.safeSearchStatus)
        do {
            return ProtectionSettings(
                protection: ServerStatusMapper.map(try await status, now: .now).filtering,
                safeBrowsing: try await safeBrowsing.enabled ?? false,
                parentalControl: try await parental.enabled ?? false,
                safeSearch: try await safeSearch.enabled
            )
        } catch {
            // `async let` erases the typed error; all calls only throw APIError.
            throw APIError(error)
        }
    }

    func updateProtection(_ change: ProtectionChange) async throws(APIError) {
        switch change {
        case .enableProtection:
            try await client.write(.protection, body: SetProtectionRequestDTO(enabled: true, duration: nil))
        case let .pauseProtection(pause):
            try await client.write(.protection, body: SetProtectionRequestDTO(enabled: false, duration: pause.milliseconds))
        case .disableProtection:
            try await client.write(.protection, body: SetProtectionRequestDTO(enabled: false, duration: nil))
        case let .safeBrowsing(isOn):
            try await client.write(isOn ? .safeBrowsingEnable : .safeBrowsingDisable)
        case let .parentalControl(isOn):
            try await client.write(isOn ? .parentalEnable : .parentalDisable)
        case let .safeSearch(isOn):
            // The settings endpoint replaces the whole config, so engine
            // settings are read first and sent back unchanged.
            var settings: SafeSearchSettingsDTO = try await client.get(.safeSearchStatus)
            settings.values["enabled"] = isOn
            try await client.write(.safeSearchSettings, method: .put, body: settings)
        }
    }
}
