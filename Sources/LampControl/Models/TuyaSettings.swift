import Foundation

enum TuyaRegion: String, Codable, CaseIterable, Hashable {
    case eu
    case us
    case usEast
    case cn
    case `in`
    case custom
}

struct TuyaSettings: Codable, Equatable {
    var accessId = ""
    var accessSecret = ""
    var endpoint = TuyaRegion.eu.defaultEndpoint
    var uid = ""
    var region: TuyaRegion = .eu

    mutating func applyEndpoint(for region: TuyaRegion) {
        guard region != .custom else { return }
        endpoint = region.defaultEndpoint
    }
}

extension TuyaRegion {
    var defaultEndpoint: String {
        switch self {
        case .eu:
            return "https://openapi.tuyaeu.com"
        case .us:
            return "https://openapi.tuyaus.com"
        case .usEast:
            return "https://openapi-ueaz.tuyaus.com"
        case .cn:
            return "https://openapi.tuyacn.com"
        case .in:
            return "https://openapi.tuyain.com"
        case .custom:
            return ""
        }
    }
}

struct StoredSettings: Codable {
    var accessId: String
    var endpoint: String
    var uid: String
    var region: TuyaRegion

    init(settings: TuyaSettings) {
        accessId = settings.accessId.trimmingCharacters(in: .whitespacesAndNewlines)
        endpoint = settings.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        uid = settings.uid.trimmingCharacters(in: .whitespacesAndNewlines)
        region = settings.region
    }

    func toSettings() -> TuyaSettings {
        TuyaSettings(accessId: accessId, accessSecret: "", endpoint: endpoint, uid: uid, region: region)
    }
}

struct SettingsSnapshot {
    var settings: TuyaSettings
    var hasSecret: Bool
}
