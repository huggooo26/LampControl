import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var route: SettingsRoute = .overview
    @State private var newYeelightHost: String = ""
    @State private var newYeelightName: String = ""
    @State private var newNanoleafHost: String = ""
    @State private var newNanoleafName: String = ""
    @State private var newWizHost: String = ""
    @State private var newWizName: String = ""
    @State private var editingAutomation: Automation?
    @State private var isAddingAutomation = false

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
                    case .lifx:
                        lifxSettings
                    case .govee:
                        goveeSettings
                    case .yeelight:
                        yeelightSettings
                    case .nanoleaf:
                        nanoleafSettings
                    case .wiz:
                        wizSettings
                    case .shortcuts:
                        shortcutsSettings
                    case .automations:
                        automationsSettings
                    case .circadian:
                        circadianSettings_
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
                        .frame(width: 34, height: 34)
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
                    .shortcuts,
                    icon: "keyboard",
                    title: "Raccourcis clavier",
                    subtitle: "⌥0 Éteindre · ⌥1-⌥4 Scènes",
                    tint: Color.purple.opacity(0.10)
                )

                settingsLink(
                    .automations,
                    icon: "clock.badge.checkmark.fill",
                    title: "Automations",
                    subtitle: appState.automations.isEmpty ? "Planifiez vos lampes" : "\(appState.automations.filter(\.isEnabled).count) active(s)",
                    tint: Color.green.opacity(0.10)
                )

                settingsLink(
                    .circadian,
                    icon: "sun.and.horizon.fill",
                    title: "Éclairage adaptatif",
                    subtitle: appState.circadianSettings.isEnabled ? "Actif" : "Ajuste temp. selon l'heure",
                    tint: Color.orange.opacity(0.10)
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
                .foregroundStyle(isConfigured ? Color.green.opacity(0.85) : (provider.isImplemented ? accent : muted))
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

            Button {
                route = route(for: provider)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(width: 28, height: 28)
            }
            .liquidGlassButtonStyle()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .liquidGlassSurface(radius: 16, interactive: true)
    }

    private func providerIcon(_ provider: LightProviderKind) -> String {
        switch provider {
        case .tuya:       "cloud.fill"
        case .philipsHue: "dot.radiowaves.left.and.right"
        case .lifx:       "network"
        case .yeelight:   "wifi"
        case .govee:      "sparkles"
        case .nanoleaf:   "triangle.fill"
        case .wiz:        "lightbulb.2.fill"
        }
    }

    private func providerSubtitle(_ provider: LightProviderKind, isConfigured: Bool) -> String {
        if isConfigured {
            return "Connecté et utilisé pour la synchronisation"
        }

        switch provider {
        case .tuya:       return "Compte Smart Life / Tuya Cloud"
        case .philipsHue: return "Bridge Hue local (LAN)"
        case .lifx:       return "Token LIFX Cloud"
        case .govee:      return "Clé API Govee Developer"
        case .yeelight:   return "Lampes en LAN (mode développeur)"
        case .nanoleaf:   return "Panneaux lumineux en LAN"
        case .wiz:        return "Ampoules WiZ en LAN (Signify)"
        }
    }

    private func route(for provider: LightProviderKind) -> SettingsRoute {
        switch provider {
        case .tuya:       .tuya
        case .philipsHue: .hue
        case .lifx:       .lifx
        case .govee:      .govee
        case .yeelight:   .yeelight
        case .nanoleaf:   .nanoleaf
        case .wiz:        .wiz
        }
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

    private var lifxSettings: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: appState.lifxSettings.isConfigured ? "checkmark.seal.fill" : "network")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(appState.lifxSettings.isConfigured ? Color.green : accent)
                        .frame(width: 32, height: 32)
                        .liquidGlassSurface(radius: 12, tint: appState.lifxSettings.isConfigured ? Color.green.opacity(0.10) : Color.blue.opacity(0.08))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.lifxSettings.isConfigured ? "LIFX connecté" : "Connecter LIFX Cloud")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Collez un token personnel LIFX pour synchroniser vos lampes.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                    }

                    Spacer()
                }

                SecureField(appState.lifxSettings.isConfigured ? "Token LIFX enregistré" : "Token LIFX", text: $appState.lifxSettings.token)
                    .textFieldStyle(.plain)
                    .foregroundStyle(ink)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .liquidGlassSurface(radius: 13, tint: Color.white.opacity(0.08), interactive: true)

                Button {
                    Task { await appState.saveLifxSettingsAndSync() }
                } label: {
                    Label("Enregistrer et synchroniser", systemImage: "bolt.badge.checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .liquidGlassButtonStyle(prominent: true)
                .disabled(appState.isBusy || appState.lifxSettings.token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Text("Créez le token dans votre compte LIFX Cloud, puis collez-le ici. Il est stocké localement dans le Keychain macOS.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .liquidGlassSurface(radius: 22)
        }
    }

    private var goveeSettings: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: appState.goveeSettings.isConfigured ? "checkmark.seal.fill" : "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(appState.goveeSettings.isConfigured ? Color.green : accent)
                        .frame(width: 32, height: 32)
                        .liquidGlassSurface(radius: 12, tint: appState.goveeSettings.isConfigured ? Color.green.opacity(0.10) : Color.purple.opacity(0.08))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.goveeSettings.isConfigured ? "Govee connecté" : "Connecter Govee Cloud")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Demandez une clé API depuis l'app Govee Home (\u{2261} → À propos → Apply for API Key).")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                    }

                    Spacer()
                }

                SecureField(appState.goveeSettings.isConfigured ? "Clé API enregistrée" : "Clé API Govee", text: $appState.goveeSettings.apiKey)
                    .textFieldStyle(.plain)
                    .foregroundStyle(ink)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .liquidGlassSurface(radius: 13, tint: Color.white.opacity(0.08), interactive: true)

                Button {
                    Task { await appState.saveGoveeSettingsAndSync() }
                } label: {
                    Label("Enregistrer et synchroniser", systemImage: "bolt.badge.checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .liquidGlassButtonStyle(prominent: true)
                .disabled(appState.isBusy || appState.goveeSettings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Text("La clé est envoyée par e-mail par Govee. Limite de 60 requêtes/minute. Stockée localement dans le Keychain macOS.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .liquidGlassSurface(radius: 22)
        }
    }

    private var yeelightSettings: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: appState.yeelightSettings.isConfigured ? "checkmark.seal.fill" : "wifi")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(appState.yeelightSettings.isConfigured ? Color.green : accent)
                        .frame(width: 32, height: 32)
                        .liquidGlassSurface(radius: 12, tint: appState.yeelightSettings.isConfigured ? Color.green.opacity(0.10) : Color.orange.opacity(0.08))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.yeelightSettings.isConfigured ? "\(appState.yeelightSettings.bulbs.count) lampe(s) Yeelight" : "Ajouter une lampe Yeelight")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Activez « LAN Control » dans l'app Yeelight, puis renseignez l'IP locale de la lampe.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                    }

                    Spacer()
                }

                formField("Adresse IP (ex: 192.168.1.42)", text: $newYeelightHost, icon: "network")
                formField("Nom (optionnel)", text: $newYeelightName, icon: "tag")

                Button {
                    Task {
                        await appState.addYeelightBulb(host: newYeelightHost, name: newYeelightName)
                        newYeelightHost = ""
                        newYeelightName = ""
                    }
                } label: {
                    Label("Ajouter et synchroniser", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .liquidGlassButtonStyle(prominent: true)
                .disabled(appState.isBusy || newYeelightHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Text("L'IP est visible dans l'app Yeelight (paramètres de la lampe → Informations sur l'appareil). LAN Control doit être activé sur chaque ampoule.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .liquidGlassSurface(radius: 22)

            if !appState.yeelightSettings.bulbs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(appState.yeelightSettings.bulbs) { bulb in
                        HStack(spacing: 10) {
                            Image(systemName: "lightbulb")
                                .foregroundStyle(accent)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bulb.name)
                                    .font(.system(size: 12, weight: .semibold))
                                Text("\(bulb.host):\(bulb.port)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(muted)
                            }
                            Spacer()
                            Button {
                                Task { await appState.removeYeelightBulb(bulb) }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.red)
                                    .frame(width: 28, height: 28)
                            }
                            .liquidGlassButtonStyle()
                            .disabled(appState.isBusy)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .liquidGlassSurface(radius: 14)
                    }
                }
                .padding(12)
                .liquidGlassSurface(radius: 22)
            }
        }
    }

    // MARK: - Nanoleaf Settings

    private var nanoleafSettings: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: appState.nanoleafSettings.isConfigured ? "checkmark.seal.fill" : "triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(appState.nanoleafSettings.isConfigured ? Color.green : Color.orange)
                        .frame(width: 32, height: 32)
                        .liquidGlassSurface(radius: 12, tint: appState.nanoleafSettings.isConfigured ? Color.green.opacity(0.10) : Color.orange.opacity(0.08))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.nanoleafSettings.isConfigured ? "\(appState.nanoleafSettings.devices.count) panneau(x) Nanoleaf" : "Ajouter un panneau Nanoleaf")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Maintenez le bouton power 5-7s jusqu'au clignotement, puis appuyez sur Appairer.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                formField("Adresse IP (ex: 192.168.1.50)", text: $newNanoleafHost, icon: "network")
                formField("Nom (optionnel)", text: $newNanoleafName, icon: "tag")

                Button {
                    Task {
                        await appState.addNanoleafDevice(host: newNanoleafHost, name: newNanoleafName)
                        newNanoleafHost = ""
                        newNanoleafName = ""
                    }
                } label: {
                    Label("Appairer et synchroniser", systemImage: "link.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .liquidGlassButtonStyle(prominent: true)
                .disabled(appState.isBusy || newNanoleafHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                hint("Le port par défaut est 16021. Assurez-vous que le panneau est sur le même réseau Wi-Fi.")
            }
            .padding(14)
            .liquidGlassSurface(radius: 22)

            if !appState.nanoleafSettings.devices.isEmpty {
                VStack(spacing: 8) {
                    ForEach(appState.nanoleafSettings.devices) { device in
                        HStack(spacing: 10) {
                            Image(systemName: "triangle.fill")
                                .foregroundStyle(Color.orange)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.system(size: 12, weight: .semibold))
                                Text("\(device.host):\(device.port)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(muted)
                            }
                            Spacer()
                            Button {
                                Task { await appState.removeNanoleafDevice(device) }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.red)
                                    .frame(width: 28, height: 28)
                            }
                            .liquidGlassButtonStyle()
                            .disabled(appState.isBusy)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .liquidGlassSurface(radius: 14)
                    }
                }
                .padding(12)
                .liquidGlassSurface(radius: 22)
            }
        }
    }

    // MARK: - WiZ Settings

    private var wizSettings: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: appState.wizSettings.isConfigured ? "checkmark.seal.fill" : "lightbulb.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(appState.wizSettings.isConfigured ? Color.green : Color.cyan)
                        .frame(width: 32, height: 32)
                        .liquidGlassSurface(radius: 12, tint: appState.wizSettings.isConfigured ? Color.green.opacity(0.10) : Color.cyan.opacity(0.08))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.wizSettings.isConfigured ? "\(appState.wizSettings.devices.count) ampoule(s) WiZ" : "Ajouter une ampoule WiZ")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Ampoules WiZ (Signify) sur le même réseau. Aucune configuration requise.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                    }
                    Spacer()
                }

                formField("Adresse IP (ex: 192.168.1.55)", text: $newWizHost, icon: "network")
                formField("Nom (optionnel)", text: $newWizName, icon: "tag")

                Button {
                    Task {
                        await appState.addWizDevice(host: newWizHost, name: newWizName)
                        newWizHost = ""
                        newWizName = ""
                    }
                } label: {
                    Label("Ajouter et synchroniser", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .liquidGlassButtonStyle(prominent: true)
                .disabled(appState.isBusy || newWizHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                hint("L'IP est visible dans l'app WiZ (paramètres de l'ampoule). Port UDP 38899.")
            }
            .padding(14)
            .liquidGlassSurface(radius: 22)

            if !appState.wizSettings.devices.isEmpty {
                VStack(spacing: 8) {
                    ForEach(appState.wizSettings.devices) { device in
                        HStack(spacing: 10) {
                            Image(systemName: "lightbulb.2.fill")
                                .foregroundStyle(Color.cyan)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.system(size: 12, weight: .semibold))
                                Text("\(device.host)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(muted)
                            }
                            Spacer()
                            Button {
                                Task { await appState.removeWizDevice(device) }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.red)
                                    .frame(width: 28, height: 28)
                            }
                            .liquidGlassButtonStyle()
                            .disabled(appState.isBusy)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .liquidGlassSurface(radius: 14)
                    }
                }
                .padding(12)
                .liquidGlassSurface(radius: 22)
            }
        }
    }

    // MARK: - Automations Settings

    private var automationsSettings: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.green)
                        .frame(width: 32, height: 32)
                        .liquidGlassSurface(radius: 12, tint: Color.green.opacity(0.10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automations")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Déclenchez des actions à heure fixe, chaque jour ou certains jours.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding(12)
                .liquidGlassSurface(radius: 16)

                if appState.automations.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.badge.xmark")
                            .foregroundStyle(muted)
                            .frame(width: 24, height: 24)
                        Text("Aucune automation. Créez-en une ci-dessous.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(muted)
                        Spacer()
                    }
                    .padding(12)
                    .liquidGlassSurface(radius: 14)
                } else {
                    ForEach(appState.automations) { automation in
                        HStack(spacing: 10) {
                            Image(systemName: automation.action.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(automation.isEnabled ? accent : muted)
                                .frame(width: 28, height: 28)
                                .liquidGlassSurface(radius: 10, tint: automation.isEnabled ? accent.opacity(0.10) : nil)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(automation.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ink)
                                Text("\(automation.timeString) · \(automation.weekdaysLabel)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(muted)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { automation.isEnabled },
                                set: { _ in appState.toggleAutomation(automation) }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .scaleEffect(0.8)

                            Button {
                                appState.deleteAutomation(automation)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.red)
                                    .frame(width: 26, height: 26)
                            }
                            .liquidGlassButtonStyle()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .liquidGlassSurface(radius: 14)
                    }
                }

                if isAddingAutomation {
                    AutomationEditor(isPresented: $isAddingAutomation) { automation in
                        appState.saveAutomation(automation)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if !isAddingAutomation {
                    Button { isAddingAutomation = true } label: {
                        Label("Nouvelle automation", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                    }
                    .liquidGlassButtonStyle(prominent: appState.licenseState.entitlements.canUseAutomations)
                    .disabled(!appState.licenseState.entitlements.canUseAutomations || appState.isBusy)
                    .overlay {
                        if !appState.licenseState.entitlements.canUseAutomations {
                            HStack {
                                Spacer()
                                Label("Premium", systemImage: "crown.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.yellow)
                                    .padding(.trailing, 12)
                            }
                        }
                    }
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.88), value: isAddingAutomation)
        }
    }

    // MARK: - Circadian Settings

    private var circadianSettings_: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "sun.and.horizon.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.orange)
                        .frame(width: 32, height: 32)
                        .liquidGlassSurface(radius: 12, tint: Color.orange.opacity(0.10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Éclairage adaptatif")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Ajuste automatiquement la luminosité et la température selon l'heure.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { appState.circadianSettings.isEnabled },
                        set: { v in Task { await appState.setAdaptiveLighting(enabled: v) } }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(!appState.licenseState.entitlements.canUseAdaptiveLighting)
                }
                .padding(12)
                .liquidGlassSurface(radius: 16)

                HStack(spacing: 10) {
                    Toggle("Luminosité", isOn: $appState.circadianSettings.applyBrightness)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Toggle("Température", isOn: $appState.circadianSettings.applyTemperature)
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .liquidGlassSurface(radius: 14)

                VStack(spacing: 6) {
                    ForEach(appState.circadianSettings.keyframes.sorted(by: { $0.minuteOfDay < $1.minuteOfDay })) { kf in
                        HStack(spacing: 12) {
                            Text(String(format: "%02d:%02d", kf.hour, kf.minute))
                                .font(.system(size: 12, weight: .semibold).monospaced())
                                .foregroundStyle(accent)
                                .frame(width: 44, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(kf.brightness)% lum.")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(LCTheme.muted)
                                Text("\(kf.temperature) K")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(LCTheme.muted)
                            }
                            Spacer()
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color(hue: 0, saturation: 0, brightness: Double(kf.brightness) / 100))
                                .frame(width: 20, height: 20)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .liquidGlassSurface(radius: 12)
                    }
                }

                HStack(spacing: 8) {
                    Button {
                        Task { await appState.applyCircadianNow() }
                    } label: {
                        Label("Appliquer maintenant", systemImage: "sun.and.horizon")
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                    }
                    .liquidGlassButtonStyle(prominent: appState.circadianSettings.isEnabled)
                    .disabled(!appState.circadianSettings.isEnabled || appState.isBusy)

                    Button {
                        Task { await appState.saveCircadianSettings(appState.circadianSettings) }
                    } label: {
                        Text("Sauvegarder")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 100, height: 38)
                    }
                    .liquidGlassButtonStyle(prominent: true)
                    .tint(accent)
                    .disabled(appState.isBusy)
                }
            }
        }
    }

    // MARK: - Shortcuts Settings

    private var shortcutsSettings: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.purple)
                        .frame(width: 32, height: 32)
                        .liquidGlassSurface(radius: 12, tint: Color.purple.opacity(0.10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Raccourcis clavier globaux")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Contrôlez vos lampes sans ouvrir l'app.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(muted)
                    }
                    Spacer()
                }
                .padding(12)
                .liquidGlassSurface(radius: 16)

                ForEach($appState.shortcutSettings.bindings) { $binding in
                    HStack(spacing: 10) {
                        Image(systemName: binding.action.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(binding.isEnabled ? accent : muted)
                            .frame(width: 28, height: 28)
                            .liquidGlassSurface(radius: 10, tint: binding.isEnabled ? accent.opacity(0.10) : nil)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(binding.action.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(ink)
                            Text(binding.displayKey)
                                .font(.system(size: 10, weight: .medium).monospaced())
                                .foregroundStyle(muted)
                        }
                        Spacer()
                        Toggle("", isOn: $binding.isEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .scaleEffect(0.8)
                            .disabled(binding.keyCode == nil)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .liquidGlassSurface(radius: 14)
                    .opacity(binding.keyCode == nil ? 0.55 : 1)
                }

                Button {
                    Task { await appState.saveShortcutSettings() }
                } label: {
                    Text("Enregistrer les raccourcis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                }
                .liquidGlassButtonStyle(prominent: true)
                .tint(accent)
                .disabled(appState.isBusy)
            }
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
                        .frame(height: 38)
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
                        .frame(height: 38)
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
                .autocorrectionDisabled()
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
            .onChange(of: appState.settings.region) { _ in
                appState.settings.applyEndpoint(for: appState.settings.region)
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
                    .frame(height: 38)
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
                    .frame(height: 38)
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
                    .frame(height: 38)
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
                .autocorrectionDisabled()
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
        HStack(alignment: .top, spacing: 5) {
            Image(systemName: "info.circle")
                .font(.system(size: 10))
                .foregroundStyle(accent)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 3)
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
        guard let url = URL(string: "https://github.com/hugoinformatique/LampControl/blob/main/docs/CONFIGURATION.fr.md") else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - AutomationEditor

private struct AutomationEditor: View {
    @Binding var isPresented: Bool
    var onSave: (Automation) -> Void

    @State private var name = ""
    @State private var hour = 22
    @State private var minute = 0
    @State private var action: AutomationAction = .powerOffAll
    @State private var weekdays = Set<Int>()

    private let actions: [AutomationAction] = [
        .powerOffAll, .powerOnAll,
        .applyScenePreset(id: "focus"), .applyScenePreset(id: "relax"),
        .applyScenePreset(id: "neon"),  .applyScenePreset(id: "night"),
    ]
    private let dayLabels = ["L", "M", "M", "J", "V", "S", "D"]

    var body: some View {
        VStack(spacing: 10) {
            TextField("Nom (ex: Extinction nocturne)", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .autocorrectionDisabled()
                .padding(.horizontal, 10)
                .frame(height: 34)
                .liquidGlassSurface(radius: 12, tint: Color.white.opacity(0.06), interactive: true)

            HStack(spacing: 8) {
                Stepper(value: $hour, in: 0...23) {
                    Text(String(format: "H %02d", hour))
                        .font(.system(size: 12, weight: .semibold).monospaced())
                        .frame(width: 52)
                }
                Stepper(value: $minute, in: 0...59, step: 5) {
                    Text(String(format: "M %02d", minute))
                        .font(.system(size: 12, weight: .semibold).monospaced())
                        .frame(width: 52)
                }
            }

            Picker("Action", selection: $action) {
                ForEach(actions, id: \.title) { a in
                    Label(a.title, systemImage: a.icon).tag(a)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 34)
            .liquidGlassSurface(radius: 12, tint: Color.white.opacity(0.06))

            HStack(spacing: 6) {
                Text("Jours:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LCTheme.muted)
                ForEach(1...7, id: \.self) { day in
                    Button {
                        if weekdays.contains(day) { weekdays.remove(day) }
                        else { weekdays.insert(day) }
                    } label: {
                        Text(dayLabels[day - 1])
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(weekdays.contains(day) ? Color.white : LCTheme.muted)
                            .frame(width: 24, height: 24)
                            .liquidGlassCircle(tint: weekdays.contains(day) ? LCTheme.accent.opacity(0.50) : nil)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Button {
                    let a = Automation(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? action.title : name.trimmingCharacters(in: .whitespacesAndNewlines),
                        hour: hour, minute: minute,
                        weekdays: weekdays, action: action
                    )
                    onSave(a)
                    isPresented = false
                } label: {
                    Label("Créer", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                }
                .liquidGlassButtonStyle(prominent: true)

                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 34, height: 34)
                }
                .liquidGlassButtonStyle()
                .foregroundStyle(LCTheme.muted)
            }
        }
        .padding(12)
        .liquidGlassSurface(radius: 18, tint: Color.white.opacity(0.05))
    }
}

private enum SettingsRoute {
    case overview
    case providers
    case tuya
    case hue
    case lifx
    case govee
    case yeelight
    case nanoleaf
    case wiz
    case shortcuts
    case automations
    case circadian
    case devices
    case updates
    case premium
    case about

    var title: String {
        switch self {
        case .overview: "Réglages"
        case .providers: "Fournisseurs"
        case .tuya:      "Compte Tuya"
        case .hue:       "Philips Hue"
        case .lifx:      "LIFX"
        case .govee:     "Govee"
        case .yeelight:  "Yeelight"
        case .nanoleaf:    "Nanoleaf"
        case .wiz:         "WiZ"
        case .shortcuts:   "Raccourcis"
        case .automations: "Automations"
        case .circadian:   "Éclairage adaptatif"
        case .devices:     "Appareils"
        case .updates:   "Mises à jour"
        case .premium:   "Premium"
        case .about:     "À propos"
        }
    }

    @MainActor
    func subtitle(appState: AppState) -> String {
        switch self {
        case .overview:
            appState.canSync ? "Configuration active" : "Configuration requise"
        case .providers:
            "Tuya, Hue, LIFX, Govee, Yeelight, Nanoleaf, WiZ"
        case .tuya:
            "Identifiants Smart Life / Tuya Cloud"
        case .hue:
            appState.hueSettings.isConfigured ? "Bridge Hue connecté" : "Bridge local à connecter"
        case .lifx:
            appState.lifxSettings.isConfigured ? "Token Cloud configuré" : "Token LIFX requis"
        case .govee:
            appState.goveeSettings.isConfigured ? "Clé API enregistrée" : "Clé API Govee requise"
        case .yeelight:
            appState.yeelightSettings.isConfigured ? "\(appState.yeelightSettings.bulbs.count) lampe(s) en LAN" : "Aucune lampe enregistrée"
        case .nanoleaf:
            appState.nanoleafSettings.isConfigured ? "\(appState.nanoleafSettings.devices.count) panneau(x) en LAN" : "Aucun panneau enregistré"
        case .wiz:
            appState.wizSettings.isConfigured ? "\(appState.wizSettings.devices.count) ampoule(s) en LAN" : "Aucune ampoule enregistrée"
        case .shortcuts:
            "Raccourcis ⌥0–⌥4 configurables"
        case .automations:
            appState.automations.isEmpty ? "Aucune automation" : "\(appState.automations.filter(\.isEnabled).count)/\(appState.automations.count) actives"
        case .circadian:
            appState.circadianSettings.isEnabled ? "Actif — \(appState.circadianSettings.keyframes.count) points de contrôle" : "Désactivé"
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
