import Foundation

/// Shared JSON coding for the AdGuard Home REST API (snake_case keys).
nonisolated extension JSONEncoder {
    static var adGuard: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

nonisolated extension JSONDecoder {
    static var adGuard: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
