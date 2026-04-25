import AppKit
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
                setupChecklist

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

    private var setupChecklist: some View {
        VStack(spacing: 11) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(LCTheme.softAccent.opacity(0.55), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: setupProgress)
                        .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(completedSetupCount)/\(setupSteps.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ink)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isSetupComplete ? "Configuration prête" : "Configuration incomplète")
                        .font(.system(size: 15, weight: .semibold))
                    Text(isSetupComplete ? "Vous pouvez enregistrer et synchroniser." : "Complétez les champs manquants.")
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
                        .liquidGlassCircle(interactive: true)
                }
                .buttonStyle(.plain)
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
            tint: step.isComplete ? Color.green.opacity(0.12) : Color.white.opacity(0.06),
            interactive: false
        )
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
