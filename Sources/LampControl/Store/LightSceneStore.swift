import Foundation

final class LightSceneStore {
    func load() throws -> [UserLightScene] {
        guard FileManager.default.fileExists(atPath: scenesURL.path) else {
            return []
        }

        let data = try Data(contentsOf: scenesURL)
        return try JSONDecoder().decode([UserLightScene].self, from: data)
    }

    func save(_ scenes: [UserLightScene]) throws {
        let data = try JSONEncoder().encode(scenes)
        try data.write(to: scenesURL, options: .atomic)
    }

    private var scenesURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LampControl", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory.appendingPathComponent("scenes.json")
    }
}
