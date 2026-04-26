import Foundation

final class LicenseStore {
    func load() throws -> LicenseState {
        guard FileManager.default.fileExists(atPath: licenseURL.path) else {
            let state = LicenseState.earlyAccess
            try save(state)
            return state
        }

        let data = try Data(contentsOf: licenseURL)
        return try JSONDecoder().decode(LicenseState.self, from: data)
    }

    func save(_ state: LicenseState) throws {
        let data = try JSONEncoder().encode(state)
        try data.write(to: licenseURL, options: .atomic)
    }

    private var licenseURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LampControl", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory.appendingPathComponent("license.json")
    }
}
