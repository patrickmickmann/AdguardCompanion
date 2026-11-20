import Foundation

/// `components/schemas/FilterConfig`.
nonisolated struct FilterConfigDTO: Encodable, Sendable {
    let enabled: Bool
    let interval: Int
}

/// `components/schemas/AddUrlRequest`.
nonisolated struct AddURLRequestDTO: Encodable, Sendable {
    let name: String
    let url: String
    let whitelist: Bool
}

/// `components/schemas/RemoveUrlRequest`.
nonisolated struct RemoveURLRequestDTO: Encodable, Sendable {
    let url: String
    let whitelist: Bool
}

/// `components/schemas/FilterSetUrl` with `FilterSetUrlData`.
nonisolated struct SetFilterURLRequestDTO: Encodable, Sendable {
    struct Data: Encodable, Sendable {
        let enabled: Bool
        let name: String
        let url: String
    }

    let url: String
    let whitelist: Bool
    let data: Data
}

/// `components/schemas/FilterRefreshRequest`.
nonisolated struct FilterRefreshRequestDTO: Encodable, Sendable {
    let whitelist: Bool
}

/// `components/schemas/FilterRefreshResponse`.
nonisolated struct FilterRefreshResponseDTO: Decodable, Sendable {
    let updated: Int?
}
