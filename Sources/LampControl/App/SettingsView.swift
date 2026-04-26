import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var route: SettingsRoute = .overview

    private let ink = LCTheme.ink
    private let muted = LCTheme.muted
    private let accent = LCTheme.accent

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 14) {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 12) {
            settingsNavigationBar

            ScrollView {
                Group {
                    switch route {
                    case .overview:
                        overview
                    case .providers:
                        providersSettings
                    case .tuya:
                        tuyaSettings
                    case .hue:
                        hueSettings
                    case .devices:
                        devicesSettings
                    case .updates:
                        updatesSettings
                    case .premium:
                        PremiumSettingsView(licenseState: appState.licenseState)
                    case .about:
                        aboutSettings
                    }
                }
                .padding(.bottom, 4)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(ink)
    }

    private var settingsNavigationBar: some View {
        HStack(spacing: 10) {
            if route != .overview {
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                        route = .overview
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accent)
                        .frame(width: 32, height: 32)
                }
                .liquidGlassButtonStyle()
                .help("Retour")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(route.title)
                    .font(.system(size: 17, weight: .semibold))
                Text(route.subtitle(appState: appState))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(muted)
                    .lineLimit(1)
            }

            Spacer()
        }
        .frame(height: 42)
    }

    private var overview: some View {
        VStack(spacing: 12) {
            setupSummary

            VStack(spacing: 8) {
                settingsLink(
                    .providers,
                    icon: "square.grid.2x2",
                    title: "Fournisseurs",
                    subtitle: "\(appState.configuredProviderKinds.count) connecté(s), \(LightProviderKind.allCases.count - appState.configuredProviderKinds.count) à venir",
                    tint: Color.cyan.opacity(0.10)
                )

                settingsLink(
                    .tuya,
                    icon: "lock.shield",
                    title: "Compte Tuya",
                    subtitle: appState.hasSecret ? "Secret stocké dans le Keychain" : "Identifiants requis",
                    tint: appState.canSync ? Color.green.opacity(0.12) : Color.orange.opacity(0.12)
                )

                settingsLink(
                    .devices,
                    icon: "lightbulb.2",
                    title: "Appareils",
                    subtitle: "\(appState.lamps.count) lampe(s), \(appState.lamps.filter(\.online).count) en ligne",
                    tint: Color.blue.opacity(0.10)
                )

                settingsLink(
                    .updates,
                    icon: "arrow.down.circle",
                    title: "Mises à jour",
                    subtitle: "Version \(appState.updateService.currentVersion) (build \(appState.updateService.currentBuild))",
                    tint: Color.purple.opacity(0.10)
                )

                settingsLink(
                    .premium,
                    icon: "crown.fill",
                    title: "Premium",
                    subtitle: "\(appState.licenseState.tier.title) - \(appState.licenseState.statusText)",
                    tint: Color.yellow.opacity(0.12)
                )

                settingsLink(
                    .about,
                    icon: "info.circle",
                    title: "À propos",
                    subtitle: "LampControl et diagnostics",
                    tint: Color.gray.opacity(0.10)
                )
            }
            .padding(10)
            .liquidGlassSurface(radius: 22)
        }
    }

    private var providersSettings: some View {
        VStack(spacing: 10) {
            ForEach(LightProviderKind.allCases, id: \.self) { provider in
                let isConfigured = appState.configuredProviderKinds.contains(provider)
                providerRow(provider, isConfigured: isConfigured)
            }
        }
        .padding(12)
        .liquidGlassSurface(radius: 22)
    }

    private func providerRow(_ provider: LightProviderKind, isConfigured: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: providerIcon(provider))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isConfigured ? Color.green : (provider.isImplemented ? accent : muted))
                .frame(width: 30, height: 30)
                .liquidGlassSurface(radius: 11, tint: isConfigured ? Color.green.opacity(0.10) : nil)

            VStack(alignment: .leading, spacing: 2) {
                Text(provider.title)
                    .font(.system(size: 12, weight: .semibold))
                Text(providerSubtitle(provider, isConfigured: isConfigured))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(muted)
            }

            Spacer()

            if provider == .tuya || provider == .philipsHue {
                Button {
                    route = provider == .tuya ? .tuya : .hue
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)
                        .frame(width: 28, height: 28)
                }
                .liquidGlassButtonStyle()
            } else {
                Text("Bientôt")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .liquidGlassSurface(radius: 10)
            }
        }
    }

    private func providerIcon(_ provider: LightProviderKind) -> String {
        switch provider {
        case .tuya: "cloud.fill"
        case .philipsHue: "dot.radiowaves.left.and.right"
        case .lifx: "network"
        case .yeelight: "wifi"
        case .govee: "sparkles"
        }
    }

    private func providerSubtitle(_ provider: LightProviderKind, isConfigured: Bool) -> String {
        if isConfigured {
            return "Connecté et utilisé pour la synchronisation"
        }

        return provider.isImplemented ? "Configuration disponible" : "Prévu dans la roadmap multi-marques"
    }

    private var hueSettings: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: appState.hueSettings.isConfigured ? "checkmark.seal.fill" : "dot.radiowaves.left.and.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(appState.hueSettings.isConfigured ? Color.green : accent)
                        .frame(width: 32, height: 32)
                        .liquidGlassSurface(radius: 12, tint: appState.hueSettings.isConfigured ? Color.green.opacity(0.10) : Color.blue.opacity(0.08))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.hueSettings.isConfigured ? "Philips Hue connecté" : "Connecter un bridge Hue")
                            .font(.system(size: 13, weight: .semibold))
                        Text(appState.hueSettings.bridgeIP.isEmpty ? "Détectez le bridge, appuyez sur son bouton, puis connectez." : appState.hueSettings.bridgeIP)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                    }

                    Spacer()
                }

                Button {
                    Task { await appState.discoverHueBridges() }
                } label: {
                    Label("Détecter les bridges", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .liquidGlassButtonStyle(prominent: true)
                .disabled(appState.isBusy)
            }
            .padding(14)
            .liquidGlassSurface(radius: 22)

            if !appState.discoveredHueBridges.isEmpty {
                VStack(spacing: 8) {
                    ForEach(appState.discoveredHueBridges) { bridge in
                        Button {
                            appState.selectHueBridge(bridge)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: appState.hueSettings.bridgeID == bridge.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(appState.hueSettings.bridgeID == bridge.id ? Color.green : muted)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bridge.id)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    Text(bridge.displayAddress)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(muted)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .liquidGlassSurface(radius: 14, interactive: true)
                    }
                }
                .padding(12)
                .liquidGlassSurface(radius: 22)
            }

            VStack(alignment: .leading, spacing: 10) {
                formField("IP du bridge", text: $appState.hueSettings.bridgeIP, icon: "network")

                Button {
                    Task { await appState.pairHueBridge() }
                } label: {
                    Label(appState.hueSettings.isConfigured ? "Reconnecter Hue" : "Connecter Hue", systemImage: "link")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .liquidGlassButtonStyle(prominent: true)
                .disabled(appState.isBusy || appState.hueSettings.bridgeIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Text("Avant de connecter, appuyez sur le bouton physique du bridge Hue. LampControl recevra une clé locale stockée dans le Keychain.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .liquidGlassSurface(radius: 22)
        }
    }

    private var setupSummary: some View {
        VStack(spacing: 12) {
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .stroke(LCTheme.softAccent.opacity(0.45), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: setupProgress)
                        .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(completedSetupCount)/\(setupSteps.count)")
                        .font(.system(size: 10, weight: .bold))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isSetupComplete ? "Configuration prête" : "Configuration à compléter")
                        .font(.system(size: 15, weight: .semibold))
                    Text(isSetupComplete ? "Tuya est prêt pour la synchronisation." : "Ajoutez les informations Tuya manquantes.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(muted)
                }

                Spacer()

                Button {
                    openConfigurationGuide()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 32, height: 32)
                }
                .liquidGlassButtonStyle()
                .help("Ouvrir le guide Tuya")
            }

            HStack(spacing: 7) {
                ForEach(setupSteps) { step in
                    SetupStepPill(step: step)
                }
            }
        }
        .padding(14)
        .liquidGlassSurface(radius: 22, tint: isSetupComplete ? Color.green.opacity(0.08) : Color.orange.opacity(0.08))
    }

    private func settingsLink(_ route: SettingsRoute, icon: String, title: String, subtitle: String, tint: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                self.route = route
            }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 34, height: 34)
                    .liquidGlassSurface(radius: 12, tint: tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ink)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(muted)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(muted)
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .liquidGlassSurface(radius: 16, tint: Color.white.opacity(0.04), interactive: true)
        }
        .buttonStyle(.plain)
    }

    private var tuyaSettings: some View {
        VStack(spacing: 12) {
            settingsGroup {
                formField("Access ID", text: $appState.settings.accessId, icon: "key")

                secureField

                settingsPicker

                formField("Endpoint", text: $appState.settings.endpoint, icon: "network")
                formField("UID utilisateur", text: $appState.settings.uid, icon: "person.crop.circle")
            }

            HStack(spacing: 8) {
                Button {
                    Task { await appState.saveSettings() }
                } label: {
                    Label("Enregistrer", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .liquidGlassButtonStyle(prominent: true)
                .tint(accent)
                .disabled(appState.isBusy)
                .opacity(appState.isBusy ? 0.55 : 1)

                Button {
                    Task { await appState.saveSettingsAndSync() }
                } label: {
                    Label("Tester", systemImage: "bolt.badge.checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSetupComplete ? Color.white : muted)
                        .frame(width: 108)
                        .frame(height: 40)
                }
                .liquidGlassButtonStyle(prominent: isSetupComplete)
                .tint(accent)
                .disabled(appState.isBusy || !isSetupComplete)
                .opacity(appState.isBusy || !isSetupComplete ? 0.55 : 1)
            }

            hint("Liez votre compte Smart Life au projet Cloud Tuya, puis copiez l'UID du compte lié.")
        }
    }

    private var secureField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Access Secret", icon: "lock")

            SecureField(appState.hasSecret ? "Secret enregistré" : "Access Secret", text: $appState.settings.accessSecret)
                .textFieldStyle(.plain)
                .foregroundStyle(ink)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .liquidGlassSurface(radius: 13, tint: Color.white.opacity(0.08), interactive: true)
        }
    }

    private var settingsPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Région", icon: "globe.europe.africa")

            Picker("Région", selection: $appState.settings.region) {
                Text("Europe").tag(TuyaRegion.eu)
                Text("US West").tag(TuyaRegion.us)
                Text("US East").tag(TuyaRegion.usEast)
                Text("China").tag(TuyaRegion.cn)
                Text("India").tag(TuyaRegion.in)
                Text("Custom").tag(TuyaRegion.custom)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .liquidGlassSurface(radius: 13, tint: Color.white.opacity(0.08), interactive: true)
            .onChange(of: appState.settings.region) { region in
                appState.settings.applyEndpoint(for: region)
            }
        }
    }

    private var devicesSettings: some View {
        VStack(spacing: 12) {
            settingsGroup {
                infoRow("Lampes détectées", value: "\(appState.lamps.count)", icon: "lightbulb.2")
                infoRow("En ligne", value: "\(appState.lamps.filter(\.online).count)", icon: "wifi")
                infoRow("Synchronisation", value: syncSummary, icon: "arrow.triangle.2.circlepath")
            }

            Button {
                Task { await appState.syncLamps() }
            } label: {
                Label("Synchroniser maintenant", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .liquidGlassButtonStyle(prominent: true)
            .tint(accent)
            .disabled(appState.isBusy || !appState.canSync)
            .opacity(appState.isBusy || !appState.canSync ? 0.55 : 1)

            hint(appState.canSync ? "La liste des lampes se met aussi à jour automatiquement toutes les minutes." : "Configurez le compte Tuya avant de synchroniser.")
        }
    }

    private var updatesSettings: some View {
        VStack(spacing: 12) {
            settingsGroup {
                toggleRow(
                    title: "Vérifier automatiquement",
                    subtitle: "Une fois par jour en arrière-plan",
                    isOn: $appState.updateService.automaticChecksEnabled
                )

                toggleRow(
                    title: "Installer automatiquement",
                    subtitle: "Télécharge et installe sans confirmation",
                    isOn: $appState.updateService.automaticDownloadsEnabled
                )
                .disabled(!appState.updateService.automaticChecksEnabled)
                .opacity(appState.updateService.automaticChecksEnabled ? 1 : 0.5)

                infoRow("Version actuelle", value: "\(appState.updateService.currentVersion) (\(appState.updateService.currentBuild))", icon: "number")
            }

            Button {
                appState.updateService.checkForUpdates()
            } label: {
                Label("Vérifier maintenant", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .liquidGlassButtonStyle(prominent: true)
            .tint(accent)
            .disabled(!appState.updateService.canCheckForUpdates)
            .opacity(appState.updateService.canCheckForUpdates ? 1 : 0.55)

            if let date = appState.updateService.lastCheckedAt {
                hint("Dernière vérification : \(date.formatted(date: .omitted, time: .shortened))")
            }
        }
    }

    private var aboutSettings: some View {
        VStack(spacing: 12) {
            settingsGroup {
                infoRow("Application", value: "LampControl", icon: "lightbulb.led")
                infoRow("Version", value: "\(appState.updateService.currentVersion) build \(appState.updateService.currentBuild)", icon: "shippingbox")
                infoRow("Stockage", value: "Keychain + fichiers locaux", icon: "lock.square")
            }

            Button {
                openConfigurationGuide()
            } label: {
                Label("Guide de configuration", systemImage: "book")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .liquidGlassButtonStyle()
        }
    }

    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            content()
        }
        .padding(14)
        .liquidGlassSurface(radius: 22)
    }

    private func formField(_ title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title, icon: icon)

            TextField(title, text: text)
                .textFieldStyle(.plain)
                .foregroundStyle(ink)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .liquidGlassSurface(radius: 13, tint: Color.white.opacity(0.08), interactive: true)
        }
    }

    private func fieldLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(muted)
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(muted)
            }
        }
        .toggleStyle(.switch)
        .tint(accent)
    }

    private func infoRow(_ title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .liquidGlassSurface(radius: 10)

            Text(title)
                .font(.system(size: 12, weight: .semibold))

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(muted)
                .lineLimit(1)
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var syncSummary: String {
        guard let lastSyncDate = appState.lastSyncDate else { return "Jamais" }
        return lastSyncDate.formatted(date: .omitted, time: .shortened)
    }

    private var setupSteps: [SetupStep] {
        [
            SetupStep(title: "ID", icon: "key.fill", isComplete: !appState.settings.accessId.trimmed.isEmpty),
            SetupStep(title: "Secret", icon: "lock.fill", isComplete: appState.hasSecret || !appState.settings.accessSecret.trimmed.isEmpty),
            SetupStep(title: "Région", icon: "globe.europe.africa.fill", isComplete: !appState.settings.endpoint.trimmed.isEmpty),
            SetupStep(title: "UID", icon: "person.fill", isComplete: !appState.settings.uid.trimmed.isEmpty)
        ]
    }

    private var completedSetupCount: Int {
        setupSteps.filter(\.isComplete).count
    }

    private var setupProgress: CGFloat {
        CGFloat(completedSetupCount) / CGFloat(max(setupSteps.count, 1))
    }

    private var isSetupComplete: Bool {
        completedSetupCount == setupSteps.count
    }

    private func openConfigurationGuide() {
        guard let url = URL(string: "https://github.com/huggooo26/LampControl/blob/main/docs/CONFIGURATION.fr.md") else { return }
        NSWorkspace.shared.open(url)
    }
}

private enum SettingsRoute {
    case overview
    case providers
    case tuya
    case hue
    case devices
    case updates
    case premium
    case about

    var title: String {
        switch self {
        case .overview: "Réglages"
        case .providers: "Fournisseurs"
        case .tuya: "Compte Tuya"
        case .hue: "Philips Hue"
        case .devices: "Appareils"
        case .updates: "Mises à jour"
        case .premium: "Premium"
        case .about: "À propos"
        }
    }

    @MainActor
    func subtitle(appState: AppState) -> String {
        switch self {
        case .overview:
            appState.canSync ? "Configuration active" : "Configuration requise"
        case .providers:
            "Tuya aujourd'hui, Hue et autres ensuite"
        case .tuya:
            "Identifiants Smart Life / Tuya Cloud"
        case .hue:
            appState.hueSettings.isConfigured ? "Bridge Hue connecté" : "Bridge local à connecter"
        case .devices:
            "\(appState.lamps.count) lampe(s) synchronisée(s)"
        case .updates:
            "Sparkle auto-update"
        case .premium:
            appState.licenseState.statusText
        case .about:
            "Version et informations locales"
        }
    }
}

private struct SetupStep: Identifiable {
    let title: String
    let icon: String
    let isComplete: Bool

    var id: String { title }
}

private struct SetupStepPill: View {
    let step: SetupStep

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: step.isComplete ? "checkmark.circle.fill" : step.icon)
                .font(.system(size: 10, weight: .bold))
            Text(step.title)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(step.isComplete ? LCTheme.accent : LCTheme.muted)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 26)
        .liquidGlassSurface(
            radius: 13,
            tint: step.isComplete ? Color.green.opacity(0.12) : Color.white.opacity(0.06)
        )
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
