import Foundation

final class ShortcutSettingsStore {
    func load() throws -> ShortcutSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return .default
        }
        let data = try Data(contentsOf: settingsURL)
        return try JSONDecoder().decode(ShortcutSettings.self, from: data)
    }

    func save(_ input: ShortcutSettings) throws -> ShortcutSettings {
        let data = try JSONEncoder().encode(input)
        try data.write(to: settingsURL, options: .atomic)
        return try load()
    }

    private var settingsURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LampControl", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("shortcut-settings.json")
    }
}
