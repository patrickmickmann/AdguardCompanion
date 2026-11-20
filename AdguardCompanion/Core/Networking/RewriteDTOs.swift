import Foundation

/// `components/schemas/RewriteEntry`.
nonisolated struct RewriteEntryDTO: Codable, Sendable {
    let domain: String?
    let answer: String?
    /// Optional; omitted by older servers and defaults to `true`.
    var enabled: Bool?
}

/// `components/schemas/RewriteUpdate`.
nonisolated struct RewriteUpdateDTO: Encodable, Sendable {
    let target: RewriteEntryDTO
    let update: RewriteEntryDTO
}

/// `components/schemas/RewriteSettings`.
nonisolated struct RewriteSettingsDTO: Codable, Sendable {
    let enabled: Bool?
}
