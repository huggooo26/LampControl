import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
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
        ScrollView {
            VStack(spacing: 12) {
                settingsHeader

                VStack(spacing: 11) {
                    formField("Access ID", text: $appState.settings.accessId, icon: "key")

                    SecureField(appState.hasSecret ? "Secret enregistré" : "Access Secret", text: $appState.settings.accessSecret)
                        .textFieldStyle(.plain)
                        .foregroundStyle(ink)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .liquidGlassSurface(radius: 13, tint: Color.white.opacity(0.10), interactive: true)

                    Picker("Region", selection: $appState.settings.region) {
                        Text("Europe").tag(TuyaRegion.eu)
                        Text("US West").tag(TuyaRegion.us)
                        Text("US East").tag(TuyaRegion.usEast)
                        Text("China").tag(TuyaRegion.cn)
                        Text("India").tag(TuyaRegion.in)
                        Text("Custom").tag(TuyaRegion.custom)
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .liquidGlassSurface(radius: 13, tint: Color.white.opacity(0.10), interactive: true)
                    .onChange(of: appState.settings.region) { region in
                        appState.settings.applyEndpoint(for: region)
                    }

                    formField("Endpoint", text: $appState.settings.endpoint, icon: "network")
                    formField("UID utilisateur", text: $appState.settings.uid, icon: "person.crop.circle")
                }
                .padding(14)
                .liquidGlassSurface(radius: 22)

                Button {
                    Task { await appState.saveSettings() }
                } label: {
                    Label("Enregistrer", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .liquidGlassButtonStyle(prominent: true)
                .tint(accent)
                .disabled(appState.isBusy)
                .opacity(appState.isBusy ? 0.55 : 1)

                Text("Liez votre compte Smart Life au projet Cloud Tuya, puis copiez l'UID du compte lié.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 3)

                updatesSection
            }
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(ink)
    }

    private var settingsHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .liquidGlassSurface(radius: 15)
            VStack(alignment: .leading, spacing: 2) {
                Text("Accès Tuya")
                    .font(.system(size: 15, weight: .semibold))
                Text(appState.hasSecret ? "Secret stocké dans le Keychain" : "Secret requis pour contrôler les lampes")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(muted)
            }
            Spacer()
        }
        .padding(14)
        .liquidGlassSurface(radius: 22)
    }

    private var updatesSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 40, height: 40)
                    .liquidGlassSurface(radius: 15)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mises à jour")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Version \(appState.updateService.currentVersion) (build \(appState.updateService.currentBuild))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(muted)
                }
                Spacer()
            }

            Toggle(isOn: $appState.updateService.automaticChecksEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vérifier automatiquement")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Une fois par jour en arrière-plan")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(muted)
                }
            }
            .toggleStyle(.switch)
            .tint(accent)

            Toggle(isOn: $appState.updateService.automaticDownloadsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Installer automatiquement")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Télécharge et installe sans confirmation")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(muted)
                }
            }
            .toggleStyle(.switch)
            .tint(accent)
            .disabled(!appState.updateService.automaticChecksEnabled)
            .opacity(appState.updateService.automaticChecksEnabled ? 1 : 0.5)

            Button {
                appState.updateService.checkForUpdates()
            } label: {
                Label("Vérifier maintenant", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .liquidGlassButtonStyle(prominent: true)
            .tint(accent)
            .disabled(!appState.updateService.canCheckForUpdates)
            .opacity(appState.updateService.canCheckForUpdates ? 1 : 0.55)

            if let date = appState.updateService.lastCheckedAt {
                Text("Dernière vérification : \(date.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .liquidGlassSurface(radius: 22)
    }

    private func formField(_ title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(muted)

            TextField(title, text: text)
                .textFieldStyle(.plain)
                .foregroundStyle(ink)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .liquidGlassSurface(radius: 13, tint: Color.white.opacity(0.10), interactive: true)
        }
    }
}
