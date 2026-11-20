import Foundation

extension LiveAdGuardRepository {
    func fetchBlockedServices() async throws(APIError) -> BlockedServices {
        async let all: BlockedServicesAllDTO = client.get(.blockedServices)
        async let state = client.getDocument(.blockedServicesGet)
        do {
            let catalog = try await (all.blockedServices ?? []).compactMap { service -> BlockableService? in
                guard let id = service.id, let name = service.name else { return nil }
                return BlockableService(id: id, name: name, groupID: service.groupId ?? "")
            }
            let document = try await state
            return BlockedServices(catalog: catalog, blockedIDs: Set(document["ids"]?.strings ?? []),
                                   schedule: document["schedule"])
        } catch {
            // `async let` erases the typed error; both calls only throw APIError.
            throw APIError(error)
        }
    }

    func setBlockedServices(_ ids: Set<String>, keeping current: BlockedServices) async throws(APIError) {
        var document: JSONObject = ["ids": .array(ids.sorted().map(JSONValue.string))]
        if let schedule = current.schedule {
            document["schedule"] = schedule
        }
        try await client.write(.blockedServicesUpdate, method: .put, body: document)
    }
}
