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
    @Published var isOnboardingPresented = false
    @Published var userScenes: [UserLightScene] = []
    @Published var licenseState = LicenseState.earlyAccess

    @Published var updateService = UpdateService()

    private let settingsStore = SettingsStore()
    private let sceneStore = LightSceneStore()
    private let licenseStore = LicenseStore()
    private let licenseActivationService = LicenseActivationService()
    private var deviceService: DeviceService?
    private var autoSyncTask: Task<Void, Never>?
    private let onboardingDismissedKey = "LampControl.onboarding.dismissed"

    init() {
        loadLicense()
        loadScenes()
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

    var visibleLamps: [LampDevice] {
        guard let maxLamps = licenseState.entitlements.maxLamps else {
            return lamps
        }

        return Array(lamps.prefix(maxLamps))
    }

    var hiddenLampCount: Int {
        max(0, lamps.count - visibleLamps.count)
    }

    func loadSettings() async {
        do {
            let loaded = try settingsStore.load()
            settings = loaded.settings
            hasSecret = loaded.hasSecret
            presentOnboardingIfNeeded()
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

    func saveSettingsAndSync() async {
        await runBusy {
            let saved = try settingsStore.save(settings)
            settings = saved.settings
            hasSecret = saved.hasSecret
            deviceService = nil

            let service = try makeDeviceService()
            let synced = try await service.syncLamps()
            lamps = synced
            selectedLampIds = selectedLampIds.intersection(Set(synced.map(\.id)))
            expandedLampIds = expandedLampIds.intersection(Set(synced.map(\.id)))
            lastSyncDate = Date()
            message = synced.isEmpty ? "Réglages enregistrés. Aucune lampe compatible trouvée." : "\(synced.count) lampe(s) synchronisée(s)."
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
            let updated = try await makeDeviceService().setBrightness(deviceId: lamp.id, value: value)
            updateLamp(updated)
        } catch {
            message = error.localizedDescription
        }
    }

    func previewTemperature(_ lamp: LampDevice, value: Int) {
        updateLamp(lamp.withTemperature(value))
    }

    func commitTemperature(_ lamp: LampDevice, value: Int) async {
        do {
            let updated = try await makeDeviceService().setTemperature(deviceId: lamp.id, value: value)
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
        guard licenseState.entitlements.canUseGroups else {
            message = "Les groupes sont inclus dans Premium."
            return
        }

        if selectedLampIds.contains(lamp.id) {
            selectedLampIds.remove(lamp.id)
        } else {
            selectedLampIds.insert(lamp.id)
        }

        isGroupPanelExpanded = selectedLampIds.count >= 2
    }

    func selectAllRGBLamps() {
        guard licenseState.entitlements.canUseGroups else {
            message = "Les groupes sont inclus dans Premium."
            return
        }

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
            height += 8 + 64
            height += 8 + (isGroupPanelExpanded || selectedLampIds.count >= 2 ? 206 : 54)
        }

        if hiddenLampCount > 0 {
            height += 8 + 46
        }

        if !visibleLamps.isEmpty {
            height += 8
        }

        for lamp in visibleLamps {
            height += expandedLampIds.contains(lamp.id) ? expandedLampRowHeight(for: lamp) : 48
        }

        height += CGFloat(max(0, visibleLamps.count - 1)) * 8
        height += 10

        return height
    }

    private func expandedLampRowHeight(for lamp: LampDevice) -> CGFloat {
        var height: CGFloat = 62

        height += 37

        if lamp.capabilities.colorCode != nil || lamp.capabilities.brightness != nil || lamp.capabilities.temperature != nil {
            height += 30
        }

        if lamp.capabilities.temperature != nil {
            height += 30
        }

        if lamp.capabilities.colorCode != nil {
            height += 98
        }

        return height
    }

    func applyGroupColor() async {
        guard licenseState.entitlements.canUseGroups else {
            message = "Les groupes sont inclus dans Premium."
            return
        }

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

    func applyScene(_ preset: LightScenePreset) async {
        await applyScene(title: preset.title, color: preset.color)
    }

    func applyScene(_ scene: UserLightScene) async {
        guard licenseState.entitlements.canUseCustomScenes else {
            message = "Les scènes personnalisées sont incluses dans Premium."
            return
        }

        await applyScene(title: scene.title, color: scene.color)
    }

    func saveUserScene(id: UUID?, title: String, icon: String, color: HSVColor) {
        guard licenseState.entitlements.canUseCustomScenes else {
            message = "Les scènes personnalisées sont incluses dans Premium."
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            message = "Nom de scène requis."
            return
        }

        let cleanIcon = icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "paintpalette.fill" : icon.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id, let index = userScenes.firstIndex(where: { $0.id == id }) {
            userScenes[index].title = cleanTitle
            userScenes[index].icon = cleanIcon
            userScenes[index].color = color
            message = "Scène \(cleanTitle) mise à jour."
        } else {
            userScenes.append(UserLightScene(title: cleanTitle, icon: cleanIcon, color: color))
            message = "Scène \(cleanTitle) créée."
        }

        persistScenes()
    }

    func deleteUserScene(_ scene: UserLightScene) {
        guard licenseState.entitlements.canUseCustomScenes else {
            message = "Les scènes personnalisées sont incluses dans Premium."
            return
        }

        userScenes.removeAll { $0.id == scene.id }
        persistScenes()
        message = "Scène supprimée."
    }

    private func applyScene(title: String, color: HSVColor) async {
        let selectedTargets = lamps.filter {
            selectedLampIds.contains($0.id) && $0.online && $0.capabilities.colorCode != nil
        }
        let targets = selectedTargets.isEmpty
            ? lamps.filter { $0.online && $0.capabilities.colorCode != nil }
            : selectedTargets

        guard !targets.isEmpty else {
            message = "Aucune lampe RGB en ligne pour appliquer cette ambiance."
            return
        }

        groupColor = color

        await runBusy {
            let service = try makeDeviceService()
            var updated: [LampDevice] = []
            for lamp in targets {
                updated.append(try await service.setColor(deviceId: lamp.id, color: color))
            }
            for lamp in updated {
                updateLamp(lamp)
            }
            let scope = selectedTargets.isEmpty ? "toutes les lampes RGB" : "\(updated.count) lampe(s)"
            message = "Ambiance \(title) appliquée à \(scope)."
        }
    }

    func applyGroupPower(_ value: Bool) async {
        guard licenseState.entitlements.canUseGroups else {
            message = "Les groupes sont inclus dans Premium."
            return
        }

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

    func activateLicense(_ licenseKey: String, email: String?) async {
        await runBusy {
            let next = try await licenseActivationService.activate(licenseKey: licenseKey, expectedEmail: email)
            licenseState = next
            try licenseStore.save(next)
            message = "Licence Premium activée."
        }
    }

    func validateLicense() async {
        await runBusy {
            let next = try await licenseActivationService.validate(licenseState)
            licenseState = next
            try licenseStore.save(next)
            message = "Licence Premium validée."
        }
    }

    func deactivateLicense() async {
        await runBusy {
            if licenseState.tier == .premium {
                try await licenseActivationService.deactivate(licenseState)
            }

            licenseState = .earlyAccess
            try licenseStore.save(licenseState)
            message = "Licence désactivée. Early Access actif."
        }
    }

    func openPremiumCheckout() {
        guard let url = LicenseProviderConfig.checkoutURL else {
            message = "Lien d'achat Premium à configurer."
            return
        }

        NSWorkspace.shared.open(url)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    func openOnboardingSettings() {
        isOnboardingPresented = false
        selectedTab = .settings
    }

    func dismissOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingDismissedKey)
        isOnboardingPresented = false
    }

    func openConfigurationGuide() {
        guard let url = URL(string: "https://github.com/huggooo26/LampControl/blob/main/docs/CONFIGURATION.fr.md") else { return }
        NSWorkspace.shared.open(url)
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

    private func presentOnboardingIfNeeded() {
        guard !canSync else {
            isOnboardingPresented = false
            return
        }

        isOnboardingPresented = !UserDefaults.standard.bool(forKey: onboardingDismissedKey)
    }

    private func loadScenes() {
        do {
            userScenes = try sceneStore.load()
        } catch {
            message = "Scènes locales illisibles."
        }
    }

    private func loadLicense() {
        do {
            licenseState = try licenseStore.load()
        } catch {
            licenseState = .earlyAccess
            message = "Licence locale illisible. Early Access actif."
        }
    }

    private func persistScenes() {
        do {
            try sceneStore.save(userScenes)
        } catch {
            message = error.localizedDescription
        }
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
