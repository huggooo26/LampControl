import Foundation

enum LightProviderKind: String, Codable, CaseIterable, Hashable {
    case tuya
    case philipsHue
    case lifx
    case yeelight
    case govee

    var title: String {
        switch self {
        case .tuya: "Tuya / Smart Life"
        case .philipsHue: "Philips Hue"
        case .lifx: "LIFX"
        case .yeelight: "Yeelight"
        case .govee: "Govee"
        }
    }

    var isImplemented: Bool {
        self == .tuya || self == .philipsHue
    }
}

protocol LightProvider: AnyObject {
    var kind: LightProviderKind { get }
    var displayName: String { get }

    func syncLights() async throws -> [LampDevice]
    func setPower(deviceId: String, value: Bool) async throws -> LampDevice
    func setBrightness(deviceId: String, value: Int) async throws -> LampDevice
    func setTemperature(deviceId: String, value: Int) async throws -> LampDevice
    func setColor(deviceId: String, color: HSVColor) async throws -> LampDevice
}
