import Foundation
import Security

final class KeychainStore {
    private let service = "LampControl.Tuya"
    private let account = "tuya-access-secret"

    func readSecret() throws -> String {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return ""
        }

        guard status == errSecSuccess else {
            throw LampControlError.keychain("Lecture Keychain impossible (\(status)).")
        }

        guard let data = result as? Data, let secret = String(data: data, encoding: .utf8) else {
            throw LampControlError.keychain("Secret Keychain illisible.")
        }

        return secret
    }

    func saveSecret(_ secret: String) throws {
        let data = Data(secret.utf8)
        var query = baseQuery()
        let attributes = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus != errSecItemNotFound {
            throw LampControlError.keychain("Mise à jour Keychain impossible (\(updateStatus)).")
        }

        query[kSecValueData as String] = data
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw LampControlError.keychain("Enregistrement Keychain impossible (\(addStatus)).")
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
