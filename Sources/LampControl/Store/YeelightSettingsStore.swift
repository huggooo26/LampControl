import Foundation

final class YeelightSettingsStore {
    func load() throws -> YeelightSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return YeelightSettings()
        }

        let data = try Data(contentsOf: settingsURL)
        return try JSONDecoder().decode(YeelightSettings.self, from: data)
    }

    func save(_ input: YeelightSettings) throws -> YeelightSettings {
        let data = try JSONEncoder().encode(input)
        try data.write(to: settingsURL, options: .atomic)
        return try load()
    }

    private var settingsURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LampControl", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory.appendingPathComponent("yeelight-settings.json")
    }
}
