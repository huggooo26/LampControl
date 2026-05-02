import Foundation

final class AutomationStore {
    func load() throws -> [Automation] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Automation].self, from: data)
    }

    func save(_ automations: [Automation]) throws {
        let data = try JSONEncoder().encode(automations)
        try data.write(to: url, options: .atomic)
    }

    private var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LampControl", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("automations.json")
    }
}
