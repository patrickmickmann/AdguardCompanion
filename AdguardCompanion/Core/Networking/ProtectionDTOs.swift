import Foundation

/// `components/schemas/SetProtectionRequest`.
nonisolated struct SetProtectionRequestDTO: Encodable, Sendable {
    let enabled: Bool
    /// Pause length in milliseconds; only sent together with `enabled: false`.
    let duration: Int64?
}

/// Response of `/control/safebrowsing/status` and `/control/parental/status`.
nonisolated struct EnabledStatusDTO: Decodable, Sendable {
    let enabled: Bool?
}

/// `components/schemas/SafeSearchConfig`. All fields are booleans, so the
/// config is kept as a dictionary: writing it back preserves every search
/// engine setting, including engines this app does not know about.
nonisolated struct SafeSearchSettingsDTO: Codable, Sendable, Equatable {
    var values: [String: Bool]

    var enabled: Bool { values["enabled"] ?? false }

    init(values: [String: Bool]) {
        self.values = values
    }

    init(from decoder: any Decoder) throws {
        values = try decoder.singleValueContainer().decode([String: Bool].self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}
