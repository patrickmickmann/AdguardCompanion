import Foundation
import Security

nonisolated enum KeychainError: Error, Equatable {
    case unexpectedStatus(OSStatus)
    case invalidData
}

/// Minimal wrapper around Keychain Services for generic passwords.
/// Items are device-bound and available after first unlock (needed for
/// future widgets and background refresh), never synced to iCloud.
nonisolated struct KeychainStore: Sendable {
    let service: String

    func setPassword(_ password: String, account: String) throws(KeychainError) {
        let data = Data(password.utf8)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(baseQuery(account: account) as CFDictionary, attributes as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            let query = baseQuery(account: account).merging(attributes) { _, new in new }
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw .unexpectedStatus(addStatus) }
        default:
            throw .unexpectedStatus(updateStatus)
        }
    }

    func password(account: String) throws(KeychainError) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let password = String(data: data, encoding: .utf8) else {
                throw .invalidData
            }
            return password
        case errSecItemNotFound:
            return nil
        default:
            throw .unexpectedStatus(status)
        }
    }

    /// Removes every item stored under this service.
    func removeAll() throws(KeychainError) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw .unexpectedStatus(status)
        }
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false,
        ]
    }
}
