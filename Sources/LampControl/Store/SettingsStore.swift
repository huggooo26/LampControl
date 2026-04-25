import Foundation

final class SettingsStore {
    private let keychain = KeychainStore()

    func load() throws -> SettingsSnapshot {
        let settings = try readStoredSettings().toSettings()
        let secret = try keychain.readSecret()
        return SettingsSnapshot(settings: settings, hasSecret: !secret.isEmpty)
    }

    func save(_ input: TuyaSettings) throws -> SettingsSnapshot {
        let stored = StoredSettings(settings: input)

        if !input.accessSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try keychain.saveSecret(input.accessSecret.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let data = try JSONEncoder().encode(stored)
        try data.write(to: settingsURL, options: .atomic)

        return try load()
    }

    func accessSecret() throws -> String {
        try keychain.readSecret()
    }

    private func readStoredSettings() throws -> StoredSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return StoredSettings(settings: TuyaSettings())
        }

        let data = try Data(contentsOf: settingsURL)
        return try JSONDecoder().decode(StoredSettings.self, from: data)
    }

    private var settingsURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LampControl", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory.appendingPathComponent("settings.json")
    }
}
