import Foundation

final class NanoleafSettingsStore {
    func load() throws -> NanoleafSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return NanoleafSettings()
        }
        let data = try Data(contentsOf: settingsURL)
        return try JSONDecoder().decode(NanoleafSettings.self, from: data)
    }

    func save(_ input: NanoleafSettings) throws -> NanoleafSettings {
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
        return dir.appendingPathComponent("nanoleaf-settings.json")
    }
}
