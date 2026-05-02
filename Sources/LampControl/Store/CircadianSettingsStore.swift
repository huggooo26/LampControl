import Foundation

final class CircadianSettingsStore {
    func load() throws -> CircadianSettings {
        guard FileManager.default.fileExists(atPath: url.path) else { return .default }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CircadianSettings.self, from: data)
    }

    func save(_ settings: CircadianSettings) throws -> CircadianSettings {
        let data = try JSONEncoder().encode(settings)
        try data.write(to: url, options: .atomic)
        return try load()
    }

    private var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LampControl", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("circadian-settings.json")
    }
}
