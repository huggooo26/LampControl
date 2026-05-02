import Foundation

final class ProfileStore {
    func load() throws -> [LampProfile] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([LampProfile].self, from: data)
    }

    func save(_ profiles: [LampProfile]) throws {
        let data = try JSONEncoder().encode(profiles)
        try data.write(to: url, options: .atomic)
    }

    private var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LampControl", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("profiles.json")
    }
}
