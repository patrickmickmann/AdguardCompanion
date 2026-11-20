import Foundation

extension LiveAdGuardRepository {
    func fetchFilterListSettings() async throws(APIError) -> FilterListSettings {
        let dto: FilterStatusDTO = try await client.get(.filteringStatus)
        return FilterListMapper.map(dto)
    }

    func updateFilterLists(_ change: FilterListChange, current: FilterListSettings) async throws(APIError) {
        switch change {
        case let .setFilteringEnabled(isOn):
            try await client.write(.filteringConfig,
                                   body: FilterConfigDTO(enabled: isOn, interval: current.updateIntervalHours))
        case let .setEnabled(list, isOn):
            try await client.write(.setFilterURL, body: SetFilterURLRequestDTO(
                url: list.url, whitelist: list.kind.isAllowlist,
                data: .init(enabled: isOn, name: list.name, url: list.url)
            ))
        case let .add(name, url, kind):
            try await client.write(.addFilterURL, body: AddURLRequestDTO(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                url: url.trimmingCharacters(in: .whitespacesAndNewlines),
                whitelist: kind.isAllowlist
            ))
        case let .remove(list):
            try await client.write(.removeFilterURL,
                                   body: RemoveURLRequestDTO(url: list.url, whitelist: list.kind.isAllowlist))
        }
    }

    func refreshFilterLists(_ kind: FilterList.Kind) async throws(APIError) -> Int {
        let response = try await client.write(.refreshFilters,
                                              body: FilterRefreshRequestDTO(whitelist: kind.isAllowlist),
                                              returning: FilterRefreshResponseDTO.self)
        return response.updated ?? 0
    }
}
