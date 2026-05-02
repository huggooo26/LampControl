import Foundation

final class WizSettingsStore {
    func load() throws -> WizSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return WizSettings()
        }
        let data = try Data(contentsOf: settingsURL)
        return try JSONDecoder().decode(WizSettings.self, from: data)
    }

    func save(_ input: WizSettings) throws -> WizSettings {
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
        return dir.appendingPathComponent("wiz-settings.json")
    }
}
