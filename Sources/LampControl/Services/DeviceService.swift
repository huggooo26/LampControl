import Foundation

final class DeviceService {
    private let client: TuyaClient
    private let uid: String
    private var lamps: [String: LampDevice] = [:]

    init(client: TuyaClient, uid: String) {
        self.client = client
        self.uid = uid
    }

    func syncLamps() async throws -> [LampDevice] {
        guard !uid.isEmpty else {
            throw LampControlError.configuration("UID Tuya manquant. Renseignez-le dans les réglages.")
        }

        let devices: [TuyaDeviceDTO] = try await client.get("/v1.0/users/\(urlPath(uid))/devices")
        let mapped = try await devices.asyncCompactMap { try await lamp(from: $0) }
        lamps = Dictionary(uniqueKeysWithValues: mapped.map { ($0.id, $0) })
        return mapped
    }

    func setPower(deviceId: String, value: Bool) async throws -> LampDevice {
        try await sendCommand(deviceId: deviceId, code: "switch_led", value: .bool(value))
        return try update(deviceId: deviceId) { $0.power = value }
    }

    func setBrightness(deviceId: String, value: Int) async throws -> LampDevice {
        let lamp = try requireLamp(deviceId)
        if lamp.capabilities.colorCode != nil {
            return try await setColorBrightness(deviceId: deviceId, value: value)
        }

        guard let brightness = lamp.capabilities.brightness else {
            throw LampControlError.tuya("Cette lampe ne déclare pas de réglage de luminosité.")
        }

        let safeValue = min(brightness.max, max(brightness.min, value))
        try await sendCommand(deviceId: deviceId, code: brightness.code, value: .int(safeValue))
        return try update(deviceId: deviceId) { $0.brightness = safeValue }
    }

    func setColorBrightness(deviceId: String, value: Int) async throws -> LampDevice {
        let lamp = try requireLamp(deviceId)
        guard lamp.capabilities.colorCode != nil else {
            return try await setBrightness(deviceId: deviceId, value: value)
        }

        let currentColor = (lamp.color ?? .warm).withValue(value)
        return try await setColor(deviceId: deviceId, color: currentColor)
    }

    func setColor(deviceId: String, color: HSVColor) async throws -> LampDevice {
        let lamp = try requireLamp(deviceId)
        guard let colorCode = lamp.capabilities.colorCode else {
            throw LampControlError.tuya("Cette lampe ne déclare pas de réglage couleur RGB.")
        }

        var commands: [TuyaCommand] = []
        if let switchCode = lamp.capabilities.switchCode {
            commands.append(TuyaCommand(code: switchCode, value: .bool(true)))
        }
        if let workModeCode = lamp.capabilities.workModeCode {
            commands.append(TuyaCommand(code: workModeCode, value: .string("colour")))
        }
        commands.append(TuyaCommand(code: colorCode, value: .color(color.scaled(for: colorCode))))

        try await sendCommands(deviceId: deviceId, commands: commands)
        return try update(deviceId: deviceId) {
            $0.power = true
            $0.color = color
            $0.brightness = color.v
            $0.workMode = "colour"
        }
    }

    private func lamp(from device: TuyaDeviceDTO) async throws -> LampDevice? {
        let spec: TuyaSpecResponse = try await client.get("/v1.0/devices/\(urlPath(device.id))/specifications")
        let capabilities = parseCapabilities(spec.functions ?? [])

        guard capabilities.switchCode != nil || capabilities.brightness != nil || capabilities.temperature != nil || capabilities.colorCode != nil else {
            return nil
        }

        let status = Dictionary(uniqueKeysWithValues: (device.status ?? []).map { ($0.code, $0.value) })
        let brightnessCode = capabilities.brightness?.code
        let colorCode = capabilities.colorCode

        return LampDevice(
            id: device.id,
            name: device.name,
            online: device.online,
            power: status["switch_led"]?.boolValue ?? false,
            brightness: brightnessCode.flatMap { status[$0]?.intValue } ?? capabilities.brightness?.min,
            color: colorCode.flatMap { status[$0]?.hsvValue?.normalized(from: $0) },
            workMode: status["work_mode"]?.stringValue,
            capabilities: capabilities
        )
    }

    private func sendCommand(deviceId: String, code: String, value: TuyaCommandValue) async throws {
        let lamp = try requireLamp(deviceId)
        guard lamp.online else {
            throw LampControlError.offline
        }

        let body = TuyaCommandBody(commands: [TuyaCommand(code: code, value: value)])
        let _: EmptyTuyaResult = try await client.post("/v1.0/devices/\(urlPath(deviceId))/commands", body: body)
    }

    private func sendCommands(deviceId: String, commands: [TuyaCommand]) async throws {
        let lamp = try requireLamp(deviceId)
        guard lamp.online else {
            throw LampControlError.offline
        }

        let body = TuyaCommandBody(commands: commands)
        let _: EmptyTuyaResult = try await client.post("/v1.0/devices/\(urlPath(deviceId))/commands", body: body)
    }

    private func requireLamp(_ deviceId: String) throws -> LampDevice {
        guard let lamp = lamps[deviceId] else {
            throw LampControlError.tuya("Lampe inconnue. Lancez une synchronisation.")
        }

        return lamp
    }

    private func update(deviceId: String, mutate: (inout LampDevice) -> Void) throws -> LampDevice {
        var lamp = try requireLamp(deviceId)
        mutate(&lamp)
        lamps[deviceId] = lamp
        return lamp
    }

    private func parseCapabilities(_ functions: [TuyaFunctionSpec]) -> LightCapabilities {
        let byCode = Dictionary(uniqueKeysWithValues: functions.map { ($0.code, $0) })

        return LightCapabilities(
            switchCode: byCode["switch_led"] == nil ? nil : "switch_led",
            brightness: parseNumeric(byCode["bright_value_v2"] ?? byCode["bright_value"]),
            temperature: parseNumeric(byCode["temp_value_v2"] ?? byCode["temp_value"]),
            colorCode: byCode["colour_data_v2"] == nil ? (byCode["colour_data"] == nil ? nil : "colour_data") : "colour_data_v2",
            workModeCode: byCode["work_mode"] == nil ? nil : "work_mode"
        )
    }

    private func parseNumeric(_ spec: TuyaFunctionSpec?) -> NumericCapability? {
        guard let spec else { return nil }
        guard ["bright_value", "bright_value_v2", "temp_value", "temp_value_v2"].contains(spec.code) else { return nil }

        if let values = spec.values?.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: values) as? [String: Any] {
            return NumericCapability(
                code: spec.code,
                min: json["min"] as? Int ?? 0,
                max: json["max"] as? Int ?? 1000,
                step: json["step"] as? Int ?? 1
            )
        }

        return NumericCapability(code: spec.code, min: 0, max: 1000, step: 1)
    }

    private func urlPath(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}

extension Array {
    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async throws -> [T] {
        var values: [T] = []
        for element in self {
            if let value = try await transform(element) {
                values.append(value)
            }
        }
        return values
    }
}
