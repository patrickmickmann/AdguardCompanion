import Foundation
import Observation

/// Presentation state of the user rule list.
@Observable
final class UserRulesModel {
    private(set) var rules: [String]?
    private(set) var loadError: APIError?
    var actionError: APIError?
    private(set) var isWorking = false
    private(set) var confirmedChanges = 0
    var searchText = ""
    var rulePendingRemoval: String?
    var isAdding = false

    let isDemo: Bool
    private let repository: any AdGuardRepository
    private let updater: UserRulesUpdater

    init(repository: any AdGuardRepository) {
        self.repository = repository
        self.updater = UserRulesUpdater(repository: repository)
        self.isDemo = repository.isDemo
    }

    /// Non-empty lines matching the search, in server order.
    var visibleRules: [String] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return (rules ?? []).filter { line in
            !line.trimmingCharacters(in: .whitespaces).isEmpty
                && (query.isEmpty || line.localizedCaseInsensitiveContains(query))
        }
    }

    var activeRuleCount: Int {
        (rules ?? []).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty && !UserRulesUpdater.isComment($0) }.count
    }

    func load() async {
        do {
            rules = try await repository.fetchUserRules()
            loadError = nil
        } catch {
            guard error != .cancelled else { return }
            loadError = error
        }
    }

    /// Returns whether the server confirmed the new rule.
    @discardableResult
    func add(_ rule: String) async -> Bool {
        await perform { [updater] () throws(APIError) in try await updater.add(rule) }
    }

    func remove(_ rule: String) async {
        await perform { [updater] () throws(APIError) in try await updater.remove(rule) }
    }

    @discardableResult
    private func perform(_ change: () async throws(APIError) -> [String]) async -> Bool {
        guard !isWorking else { return false }
        isWorking = true
        defer { isWorking = false }
        do {
            rules = try await change()
            confirmedChanges += 1
            return true
        } catch {
            actionError = error
            await load()
            return false
        }
    }
}
