import Foundation

final class GoveeSettingsStore {
    private let keychain = KeychainStore()
    private let keychainService = "LampControl.Govee"
    private let keychainAccount = "govee-api-key"

    func load() throws -> GoveeSettings {
        GoveeSettings(apiKey: try keychain.readSecret(service: keychainService, account: keychainAccount))
    }

    func save(_ input: GoveeSettings) throws -> GoveeSettings {
        let key = input.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty {
            try keychain.saveSecret(key, service: keychainService, account: keychainAccount)
        }

        return try load()
    }
}
