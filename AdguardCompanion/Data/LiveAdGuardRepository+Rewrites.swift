import Foundation

extension LiveAdGuardRepository {
    func fetchRewrites() async throws(APIError) -> DNSRewriteSettings {
        async let list: [RewriteEntryDTO] = client.get(.rewriteList)
        async let settings: RewriteSettingsDTO = client.get(.rewriteSettings)
        do {
            let rewrites = try await list.compactMap { entry -> DNSRewrite? in
                guard let domain = entry.domain, let answer = entry.answer else { return nil }
                return DNSRewrite(domain: domain, answer: answer, isEnabled: entry.enabled ?? true)
            }
            return DNSRewriteSettings(isEnabled: try await settings.enabled ?? true, rewrites: rewrites)
        } catch {
            // `async let` erases the typed error; both calls only throw APIError.
            throw APIError(error)
        }
    }

    func updateRewrites(_ change: DNSRewriteChange) async throws(APIError) {
        switch change {
        case let .setRewritesEnabled(isOn):
            try await client.write(.rewriteSettingsUpdate, method: .put, body: RewriteSettingsDTO(enabled: isOn))
        case let .add(rewrite):
            try await client.write(.rewriteAdd, body: Self.dto(rewrite))
        case let .update(old, new):
            try await client.write(.rewriteUpdate, method: .put,
                                   body: RewriteUpdateDTO(target: Self.dto(old), update: Self.dto(new)))
        case let .remove(rewrite):
            try await client.write(.rewriteDelete, body: Self.dto(rewrite))
        }
    }

    private static func dto(_ rewrite: DNSRewrite) -> RewriteEntryDTO {
        RewriteEntryDTO(domain: rewrite.domain, answer: rewrite.answer, enabled: rewrite.isEnabled)
    }
}
