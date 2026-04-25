import AppKit
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var settings = TuyaSettings()
    @Published var lamps: [LampDevice] = []
    @Published var selectedTab: ControlTab = .lamps
    @Published var message = ""
    @Published var isBusy = false
    @Published var hasSecret = false
    @Published var selectedLampIds = Set<String>()
    @Published var groupColor = HSVColor.warm
    @Published var lastSyncDate: Date?
    @Published var isAutoSyncing = false
    @Published var isGroupPanelExpanded = false
    @Published var expandedLampIds = Set<String>()

    @Published var updateService = UpdateService()

    private let settingsStore = SettingsStore()
    private var deviceService: DeviceService?
    private var autoSyncTask: Task<Void, Never>?

    init() {
        Task {
            await loadSettings()
            await syncLamps(silent: true)
            startAutoSync()
        }
    }

    deinit {
        autoSyncTask?.cancel()
    }

    var canSync: Bool {
        !settings.accessId.isEmpty &&
        !settings.endpoint.isEmpty &&
        !settings.uid.isEmpty &&
        (hasSecret || !settings.accessSecret.isEmpty)
    }

    func loadSettings() async {
        do {
            let loaded = try settingsStore.load()
            settings = loaded.settings
            hasSecret = loaded.hasSecret
        } catch {
            message = error.localizedDescription
        }
    }

    func saveSettings() async {
        await runBusy {
            let saved = try settingsStore.save(settings)
            settings = saved.settings
            hasSecret = saved.hasSecret
            deviceService = nil
            message = "Réglages enregistrés."
            selectedTab = .lamps
        }
    }

    func syncLamps(silent: Bool = false) async {
        guard canSync else { return }

        if silent {
            guard !isBusy && !isAutoSyncing else { return }
            isAutoSyncing = true
            defer { isAutoSyncing = false }

            do {
                let service = try makeDeviceService()
                let synced = try await service.syncLamps()
                lamps = synced
                selectedLampIds = selectedLampIds.intersection(Set(synced.map(\.id)))
                expandedLampIds = expandedLampIds.intersection(Set(synced.map(\.id)))
                lastSyncDate = Date()
            } catch {
                // Silent refresh should not interrupt normal use.
            }

            return
        }

        await runBusy {
            let service = try makeDeviceService()
            let synced = try await service.syncLamps()
            lamps = synced
            selectedLampIds = selectedLampIds.intersection(Set(synced.map(\.id)))
            expandedLampIds = expandedLampIds.intersection(Set(synced.map(\.id)))
            lastSyncDate = Date()
            message = synced.isEmpty ? "Aucune lampe compatible trouvée." : "\(synced.count) lampe(s) synchronisée(s)."
        }
    }

    func toggle(_ lamp: LampDevice) async {
        updateLamp(lamp.withPower(!lamp.power))

        do {
            let updated = try await makeDeviceService().setPower(deviceId: lamp.id, value: !lamp.power)
            updateLamp(updated)
        } catch {
            updateLamp(lamp)
            message = error.localizedDescription
        }
    }

    func previewBrightness(_ lamp: LampDevice, value: Int) {
        updateLamp(lamp.withBrightness(value))
    }

    func commitBrightness(_ lamp: LampDevice, value: Int) async {
        do {
            let service = try makeDeviceService()
            let updated: LampDevice
            if lamp.capabilities.colorCode != nil {
                updated = try await service.setColorBrightness(deviceId: lamp.id, value: value)
            } else {
                updated = try await service.setBrightness(deviceId: lamp.id, value: value)
            }
            updateLamp(updated)
        } catch {
            message = error.localizedDescription
        }
    }

    func previewColor(_ lamp: LampDevice, color: HSVColor) {
        updateLamp(lamp.withColor(color))
    }

    func commitColor(_ lamp: LampDevice, color: HSVColor) async {
        do {
            let updated = try await makeDeviceService().setColor(deviceId: lamp.id, color: color)
            updateLamp(updated)
        } catch {
            message = error.localizedDescription
        }
    }

    func toggleSelection(_ lamp: LampDevice) {
        if selectedLampIds.contains(lamp.id) {
            selectedLampIds.remove(lamp.id)
        } else {
            selectedLampIds.insert(lamp.id)
        }

        isGroupPanelExpanded = selectedLampIds.count >= 2
    }

    func selectAllRGBLamps() {
        selectedLampIds = Set(lamps.filter { $0.online && $0.capabilities.colorCode != nil }.map(\.id))
        isGroupPanelExpanded = selectedLampIds.count >= 2
    }

    func clearSelection() {
        selectedLampIds.removeAll()
        isGroupPanelExpanded = false
    }

    func toggleGroupPanel() {
        isGroupPanelExpanded.toggle()
    }

    func toggleAdvancedControls(for lamp: LampDevice) {
        if expandedLampIds.contains(lamp.id) {
            expandedLampIds.remove(lamp.id)
        } else {
            expandedLampIds.insert(lamp.id)
        }
    }

    func isAdvancedControlsExpanded(for lamp: LampDevice) -> Bool {
        expandedLampIds.contains(lamp.id)
    }

    var preferredPopoverSize: NSSize {
        NSSize(width: 410, height: preferredPopoverHeight)
    }

    private var preferredPopoverHeight: CGFloat {
        let height: CGFloat

        switch selectedTab {
        case .settings:
            height = 740
        case .lamps:
            height = lampsPopoverHeight
        }

        return min(max(height, 330), 760)
    }

    private var lampsPopoverHeight: CGFloat {
        var height: CGFloat = 32
        height += 42
        height += 12 + 42

        if !message.isEmpty {
            height += 12 + 42
        }

        height += 8 + 36
        height += 8 + 40

        if !canSync {
            height += 8 + 38
        }

        if lamps.contains(where: { $0.capabilities.colorCode != nil }) {
            height += 8 + (isGroupPanelExpanded || selectedLampIds.count >= 2 ? 206 : 54)
        }

        if !lamps.isEmpty {
            height += 8
        }

        for lamp in lamps {
            height += expandedLampIds.contains(lamp.id) ? expandedLampRowHeight(for: lamp) : 48
        }

        height += CGFloat(max(0, lamps.count - 1)) * 8
        height += 10

        return height
    }

    private func expandedLampRowHeight(for lamp: LampDevice) -> CGFloat {
        var height: CGFloat = 62

        height += 37

        if lamp.capabilities.colorCode != nil || lamp.capabilities.brightness != nil {
            height += 30
        }

        if lamp.capabilities.colorCode != nil {
            height += 98
        }

        return height
    }

    func applyGroupColor() async {
        let targets = lamps.filter { selectedLampIds.contains($0.id) && $0.capabilities.colorCode != nil }
        guard !targets.isEmpty else {
            message = "Sélectionnez au moins une lampe RGB."
            return
        }

        await runBusy {
            let service = try makeDeviceService()
            var updated: [LampDevice] = []
            for lamp in targets {
                updated.append(try await service.setColor(deviceId: lamp.id, color: groupColor))
            }
            for lamp in updated {
                updateLamp(lamp)
            }
            message = "Couleur appliquée à \(updated.count) lampe(s)."
        }
    }

    func applyGroupPower(_ value: Bool) async {
        let targets = lamps.filter { selectedLampIds.contains($0.id) }
        guard !targets.isEmpty else {
            message = "Sélectionnez au moins une lampe."
            return
        }

        await runBusy {
            let service = try makeDeviceService()
            var updated: [LampDevice] = []
            for lamp in targets {
                updated.append(try await service.setPower(deviceId: lamp.id, value: value))
            }
            for lamp in updated {
                updateLamp(lamp)
            }
            message = value ? "Groupe allumé." : "Groupe éteint."
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func makeDeviceService() throws -> DeviceService {
        if let deviceService {
            return deviceService
        }

        let secret = try settingsStore.accessSecret()
        guard !settings.accessId.isEmpty, !secret.isEmpty, !settings.endpoint.isEmpty, !settings.uid.isEmpty else {
            throw LampControlError.configuration("Identifiants Tuya incomplets. Ouvrez les réglages.")
        }

        let client = TuyaClient(accessId: settings.accessId, accessSecret: secret, endpoint: settings.endpoint)
        let service = DeviceService(client: client, uid: settings.uid)
        deviceService = service
        return service
    }

    private func updateLamp(_ next: LampDevice) {
        lamps = lamps.map { $0.id == next.id ? next : $0 }
    }

    private func startAutoSync() {
        autoSyncTask?.cancel()
        autoSyncTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await self?.syncLamps(silent: true)
            }
        }
    }

    private func runBusy(_ operation: () async throws -> Void) async {
        isBusy = true
        message = ""
        defer { isBusy = false }

        do {
            try await operation()
        } catch {
            message = error.localizedDescription
        }
    }
}

enum ControlTab {
    case lamps
    case settings
}
