import SwiftUI
import AppKit

struct LampsView: View {
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
        VStack(spacing: 8) {
            overview
            syncBar

            if !appState.canSync {
                onboardingCard
            } else if appState.lamps.isEmpty && !appState.isAutoSyncing {
                emptyStateCard
            }

            if appState.lamps.contains(where: { $0.capabilities.colorCode != nil }) {
                ScenePresetBar()
                GroupControlEntry()
            }

            if appState.hiddenLampCount > 0 {
                premiumLimitCard
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(appState.visibleLamps) { lamp in
                        LampRow(lamp: lamp)
                    }
                }
                .padding(.bottom, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(ink)
    }

    private var onboardingCard: some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                appState.selectedTab = .settings
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 32, height: 32)
                    .liquidGlassCircle()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Bienvenue dans LampControl")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ink)
                    Text("Ajoutez vos identifiants Tuya pour commencer")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(muted)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .liquidGlassSurface(radius: 16, tint: Color.orange.opacity(0.12), interactive: true)
        }
        .buttonStyle(.plain)
        .help("Ouvrir les réglages Tuya")
    }

    private var emptyStateCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.slash")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(muted)
                .frame(width: 28, height: 28)
                .liquidGlassCircle()

            VStack(alignment: .leading, spacing: 2) {
                Text("Aucune lampe trouvée")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ink)
                Text("Vérifiez que vos lampes sont allumées et liées au compte Smart Life")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlassSurface(radius: 16)
    }

    private var overview: some View {
        HStack(spacing: 8) {
            MetricPill(value: "\(appState.visibleLamps.count)", label: "lampes", icon: "lightbulb.2")
            MetricPill(value: "\(appState.visibleLamps.filter(\.online).count)", label: "en ligne", icon: "wifi")
            MetricPill(value: "\(appState.selectedLampIds.count)", label: "groupe", icon: "checkmark.circle")
        }
    }

    private var premiumLimitCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .liquidGlassSurface(radius: 10, tint: Color.yellow.opacity(0.10))

            Text("\(appState.hiddenLampCount) lampe(s) masquée(s) par l'offre gratuite")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(muted)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .liquidGlassSurface(radius: 16, tint: Color.yellow.opacity(0.08))
    }

    private var syncBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: appState.isAutoSyncing ? "arrow.triangle.2.circlepath" : "bolt.horizontal.circle")
                    .font(.system(size: 13, weight: .semibold))
                Text(syncLabel)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(muted)

            Spacer()

            Button {
                Task { await appState.syncLamps() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .liquidGlassSurface(radius: 12, interactive: true)
            }
            .buttonStyle(.plain)
            .disabled(appState.isBusy || !appState.canSync)
            .opacity(appState.isBusy || !appState.canSync ? 0.45 : 1)
            .help("Synchroniser maintenant")
        }
        .padding(.leading, 12)
        .padding(.trailing, 5)
        .padding(.vertical, 5)
        .liquidGlassSurface(radius: 17)
    }

    private var syncLabel: String {
        if appState.isAutoSyncing { return "Mise à jour..." }
        guard let lastSyncDate = appState.lastSyncDate else { return "Auto-sync 1 min" }
        return "Synchro \(lastSyncDate.formatted(date: .omitted, time: .shortened))"
    }
}

private struct ScenePresetBar: View {
    @EnvironmentObject private var appState: AppState
    @State private var isEditingScene = false
    @State private var editingSceneId: UUID?
    @State private var draftTitle = ""
    @State private var draftIcon = "paintpalette.fill"
    @State private var draftColor = HSVColor.warm

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal) {
                HStack(spacing: 7) {
                    ForEach(LightScenePreset.presets) { preset in
                        sceneButton(title: preset.title, icon: preset.icon, color: preset.color) {
                            Task { await appState.applyScene(preset) }
                        }
                    }

                    ForEach(appState.userScenes) { scene in
                        Button {
                            Task { await appState.applyScene(scene) }
                        } label: {
                            SceneChip(title: scene.title, icon: scene.icon, color: scene.color)
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.isBusy)
                        .opacity(appState.isBusy ? 0.55 : 1)
                        .help(appState.selectedLampIds.isEmpty ? "Appliquer à toutes les lampes RGB" : "Appliquer à la sélection RGB")
                        .contextMenu {
                            Button("Modifier") {
                                beginEditing(scene)
                            }
                            Button("Supprimer", role: .destructive) {
                                appState.deleteUserScene(scene)
                            }
                        }
                    }

                    Button {
                        beginCreating()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Créer")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(LCTheme.accent)
                        .frame(width: 62)
                        .frame(height: 44)
                        .liquidGlassSurface(radius: 15, tint: LCTheme.accent.opacity(0.10), interactive: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)

            if isEditingScene {
                sceneEditor
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .liquidGlassSurface(radius: 18)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: isEditingScene)
    }

    private func sceneButton(title: String, icon: String, color: HSVColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SceneChip(title: title, icon: icon, color: color)
        }
        .buttonStyle(.plain)
        .disabled(appState.isBusy)
        .opacity(appState.isBusy ? 0.55 : 1)
        .help(appState.selectedLampIds.isEmpty ? "Appliquer à toutes les lampes RGB" : "Appliquer à la sélection RGB")
    }

    private var sceneEditor: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("Nom", text: $draftTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .liquidGlassSurface(radius: 12, tint: Color.white.opacity(0.06), interactive: true)

                Picker("Icône", selection: $draftIcon) {
                    ForEach(iconChoices, id: \.self) { icon in
                        Image(systemName: icon).tag(icon)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 48, height: 32)
                .liquidGlassSurface(radius: 12, tint: Color.white.opacity(0.06), interactive: true)
            }

            HStack(spacing: 8) {
                ColorSpectrumPicker(color: Binding(
                    get: { draftColor },
                    set: { draftColor = $0.withValue(draftColor.v).vividSaturation() }
                ))
                .frame(height: 50)

                VStack(spacing: 6) {
                    Button {
                        appState.saveUserScene(id: editingSceneId, title: draftTitle, icon: draftIcon, color: draftColor)
                        isEditingScene = false
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 34, height: 24)
                    }
                    .liquidGlassButtonStyle(prominent: true)

                    Button {
                        isEditingScene = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LCTheme.muted)
                            .frame(width: 34, height: 24)
                    }
                    .liquidGlassButtonStyle()
                }
            }
        }
        .padding(10)
        .liquidGlassSurface(radius: 16, tint: Color.white.opacity(0.05))
    }

    private var iconChoices: [String] {
        ["paintpalette.fill", "sparkles", "moon.fill", "sun.max.fill", "flame.fill", "leaf.fill", "bed.double.fill"]
    }

    private func beginCreating() {
        editingSceneId = nil
        draftTitle = ""
        draftIcon = "paintpalette.fill"
        draftColor = appState.groupColor
        isEditingScene = true
    }

    private func beginEditing(_ scene: UserLightScene) {
        editingSceneId = scene.id
        draftTitle = scene.title
        draftIcon = scene.icon
        draftColor = scene.color
        isEditingScene = true
    }
}

private struct SceneChip: View {
    let title: String
    let icon: String
    let color: HSVColor

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hsv: color))
                .frame(height: 13)

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(LCTheme.ink)
                .lineLimit(1)
        }
        .frame(width: 62)
        .frame(height: 44)
        .liquidGlassSurface(radius: 15, tint: Color(hsv: color).opacity(0.10), interactive: true)
    }
}

private struct MetricPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LCTheme.accent)
                .frame(width: 18, height: 18)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LCTheme.ink)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(LCTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .liquidGlassSurface(radius: 16)
    }
}

private struct GroupControlEntry: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if appState.isGroupPanelExpanded || appState.selectedLampIds.count >= 2 {
            GroupControlPanel()
        } else {
            GroupCompactBar()
        }
    }
}

private struct GroupCompactBar: View {
    @EnvironmentObject private var appState: AppState
    private let muted = LCTheme.muted
    private let accent = LCTheme.accent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 30, height: 30)
                .liquidGlassSurface(radius: 12)

            VStack(alignment: .leading, spacing: 1) {
                Text("Groupe")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LCTheme.ink)
                Text(appState.selectedLampIds.isEmpty ? "Sélectionne 2 lampes" : "\(appState.selectedLampIds.count) sélectionnée(s)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(muted)
            }

            Spacer()

            Button {
                appState.selectAllRGBLamps()
            } label: {
                Text("RGB")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .liquidGlassSurface(radius: 14, interactive: true)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                    appState.toggleGroupPanel()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(muted)
                    .frame(width: 30, height: 30)
                    .liquidGlassCircle(interactive: true)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .liquidGlassSurface(radius: 18)
    }
}

private struct GroupControlPanel: View {
    @EnvironmentObject private var appState: AppState
    private let ink = LCTheme.ink
    private let muted = LCTheme.muted
    private let accent = LCTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    ColorSwatch(color: appState.groupColor, size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scène groupée")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ink)
                        Text("\(appState.selectedLampIds.count) sélectionnée(s)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(muted)
                    }
                }

                Spacer()

                Button {
                    appState.selectAllRGBLamps()
                } label: {
                    Text("RGB")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .liquidGlassSurface(radius: 13, interactive: true)
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent)

                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                        appState.isGroupPanelExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 26, height: 26)
                        .liquidGlassCircle(interactive: true)
                }
                .buttonStyle(.plain)
                .foregroundStyle(muted)
            }

            if appState.selectedLampIds.count < 2 {
                Text("Sélectionne au moins deux lampes pour appliquer une scène groupée.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                Button {
                    Task { await appState.applyGroupColor() }
                } label: {
                    Label("Appliquer la couleur", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButtonStyle(prominent: true)
                .tint(accent)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(height: 36)
                .disabled(appState.selectedLampIds.isEmpty || appState.isBusy)
                .opacity(appState.selectedLampIds.isEmpty || appState.isBusy ? 0.5 : 1)

                Button {
                    Task { await appState.applyGroupPower(false) }
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .liquidGlassSurface(radius: 14, interactive: true)
                }
                .buttonStyle(.plain)
                .foregroundStyle(muted)
                .disabled(appState.selectedLampIds.isEmpty || appState.isBusy)
            }

            ColorSpectrumPicker(color: Binding(
                get: { appState.groupColor },
                set: { appState.groupColor = $0.vivid() }
            ))
            .frame(height: 82)
            .opacity(appState.selectedLampIds.count >= 2 ? 1 : 0.42)
            .disabled(appState.selectedLampIds.count < 2)
        }
        .padding(14)
        .liquidGlassSurface(radius: 22)
    }
}

private struct LampRow: View {
    @EnvironmentObject private var appState: AppState
    let lamp: LampDevice

    private let ink = LCTheme.ink
    private let muted = LCTheme.muted
    private let accent = LCTheme.accent

    var body: some View {
        VStack(spacing: showsAdvancedControls ? 10 : 0) {
            HStack(spacing: 8) {
                Button {
                    Task { await appState.toggle(lamp) }
                } label: {
                    rowSummary
                }
                .buttonStyle(.plain)
                .disabled(!lamp.online)
                .opacity(lamp.online ? 1 : 0.52)
                .help("Allumer ou éteindre")

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        appState.toggleAdvancedControls(for: lamp)
                    }
                } label: {
                    Image(systemName: showsAdvancedControls ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(muted)
                        .frame(width: 30, height: 30)
                        .liquidGlassCircle(interactive: true)
                }
                .buttonStyle(.plain)
                .help(showsAdvancedControls ? "Masquer les options" : "Afficher les options")
            }

            if showsAdvancedControls {
                advancedControls
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, showsAdvancedControls ? 10 : 8)
        .background(alignment: .top) {
            if lamp.power {
                Rectangle()
                    .fill(lamp.color.map { Color(hsv: $0) } ?? Color(red: 0.96, green: 0.77, blue: 0.26))
                    .frame(height: 2)
                    .clipShape(Capsule())
                    .padding(.horizontal, 16)
            }
        }
        .liquidGlassSurface(
            radius: 17,
            tint: lamp.power ? Color.white.opacity(0.10) : nil,
            interactive: !showsAdvancedControls
        )
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Color.white.opacity(appState.selectedLampIds.contains(lamp.id) ? 0.92 : 0.48), lineWidth: appState.selectedLampIds.contains(lamp.id) ? 1 : 0.65)
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: showsAdvancedControls)
    }

    private var showsAdvancedControls: Bool {
        appState.isAdvancedControlsExpanded(for: lamp)
    }

    private var rowSummary: some View {
        HStack(spacing: 9) {
            Image(systemName: lamp.power ? "power.circle.fill" : "power.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(lamp.power ? Color(red: 0.96, green: 0.67, blue: 0.16) : muted.opacity(0.72))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(lamp.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ink)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Circle()
                        .fill(lamp.online ? (lamp.power ? Color.blue.opacity(0.68) : Color.gray.opacity(0.45)) : Color.red.opacity(0.55))
                        .frame(width: 5, height: 5)
                    Text(compactStatus)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(muted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if let color = lamp.color, lamp.capabilities.colorCode != nil {
                ColorSwatch(color: color, size: 18)
            }

            if let brightness = brightnessCapability {
                Text("\(brightnessPercentage(for: brightness))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(muted)
                    .frame(width: 32, alignment: .trailing)
            } else if let temperature = temperatureCapability {
                Text("\(temperaturePercentage(for: temperature))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(muted)
                    .frame(width: 32, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var advancedControls: some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                Button {
                    appState.toggleSelection(lamp)
                } label: {
                    Label(
                        appState.selectedLampIds.contains(lamp.id) ? "Dans le groupe" : "Ajouter au groupe",
                        systemImage: appState.selectedLampIds.contains(lamp.id) ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(appState.selectedLampIds.contains(lamp.id) ? accent : muted)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .liquidGlassSurface(radius: 14, interactive: true)
                }
                .buttonStyle(.plain)

                Spacer()
            }

            if let brightness = brightnessCapability {
                HStack(spacing: 9) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(muted)
                        .frame(width: 14)

                    Slider(
                        value: Binding(
                            get: { Double(brightnessValue(for: brightness)) },
                            set: { appState.previewBrightness(lamp, value: Int($0)) }
                        ),
                        in: Double(brightness.min)...Double(brightness.max),
                        step: Double(brightness.step),
                        onEditingChanged: { editing in
                            guard !editing else { return }
                            Task { await appState.commitBrightness(lamp, value: brightnessValue(for: brightness)) }
                        }
                    )
                    .disabled(!lamp.online)

                    Text("\(brightnessPercentage(for: brightness))%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(muted)
                        .frame(width: 32, alignment: .trailing)
                }
            }

            if let temperature = temperatureCapability {
                HStack(spacing: 9) {
                    Image(systemName: "thermometer.sun")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(muted)
                        .frame(width: 14)

                    Slider(
                        value: Binding(
                            get: { Double(temperatureValue(for: temperature)) },
                            set: { appState.previewTemperature(lamp, value: Int($0)) }
                        ),
                        in: Double(temperature.min)...Double(temperature.max),
                        step: Double(temperature.step),
                        onEditingChanged: { editing in
                            guard !editing else { return }
                            Task { await appState.commitTemperature(lamp, value: temperatureValue(for: temperature)) }
                        }
                    )
                    .disabled(!lamp.online)

                    Text(temperatureLabel(for: temperature))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(muted)
                        .frame(width: 58, alignment: .trailing)
                }
            }

            if lamp.capabilities.colorCode != nil {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(muted)
                            .frame(width: 14)

                        ColorSwatch(color: lamp.color ?? .warm, size: 22)

                        Spacer()

                        ForEach(HSVColor.quickColors, id: \.self) { color in
                            Button {
                                let hsv = color.withValue(currentColorValue).vividSaturation()
                                appState.previewColor(lamp, color: hsv)
                                Task { await appState.commitColor(lamp, color: hsv) }
                            } label: {
                                Circle()
                                    .fill(Color(hsv: color))
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Color.white.opacity(0.72), lineWidth: 0.8))
                                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                            .disabled(!lamp.online)
                        }
                    }

                    ColorSpectrumPicker(color: Binding(
                        get: { lamp.color ?? .warm },
                        set: { newColor in
                            let hsv = newColor.withValue(currentColorValue).vividSaturation()
                            appState.previewColor(lamp, color: hsv)
                        }
                    ), onCommit: { finalColor in
                        let hsv = finalColor.withValue(currentColorValue).vividSaturation()
                        Task { await appState.commitColor(lamp, color: hsv) }
                    })
                    .frame(height: 62)
                    .disabled(!lamp.online)
                    .opacity(lamp.online ? 1 : 0.45)
                }
            }
        }
    }

    private var compactStatus: String {
        if !lamp.online { return "Hors ligne" }
        return lamp.power ? "Allumée" : "Éteinte"
    }

    private var brightnessCapability: NumericCapability? {
        if let brightness = lamp.capabilities.brightness {
            return brightness
        }
        if lamp.capabilities.colorCode != nil {
            return NumericCapability(code: "colour_value", min: 10, max: 1000, step: 1)
        }
        return nil
    }

    private var temperatureCapability: NumericCapability? {
        lamp.capabilities.temperature
    }

    private func brightnessValue(for capability: NumericCapability) -> Int {
        if lamp.capabilities.brightness != nil {
            return min(capability.max, max(capability.min, lamp.brightness ?? capability.min))
        }
        if lamp.capabilities.colorCode != nil {
            return min(capability.max, max(capability.min, lamp.color?.v ?? HSVColor.defaultColorValue))
        }
        return capability.min
    }

    private func brightnessPercentage(for capability: NumericCapability) -> Int {
        Int(round(Double(brightnessValue(for: capability)) / Double(capability.max) * 100))
    }

    private func temperatureValue(for capability: NumericCapability) -> Int {
        min(capability.max, max(capability.min, lamp.temperature ?? capability.min))
    }

    private func temperaturePercentage(for capability: NumericCapability) -> Int {
        let range = max(1, capability.max - capability.min)
        return Int(round(Double(temperatureValue(for: capability) - capability.min) / Double(range) * 100))
    }

    private func temperatureLabel(for capability: NumericCapability) -> String {
        "\(temperaturePercentage(for: capability))% blanc"
    }

    private var currentColorValue: Int {
        if let colorValue = lamp.color?.v {
            return min(1000, max(10, colorValue))
        }

        if let brightness = lamp.capabilities.brightness, let value = lamp.brightness {
            let range = max(1, brightness.max - brightness.min)
            let normalized = Double(value - brightness.min) / Double(range)
            return min(1000, max(10, Int(round(normalized * 1000.0))))
        }

        return HSVColor.defaultColorValue
    }
}

extension HSVColor {
    static let quickColors: [HSVColor] = [
        HSVColor(h: 0, s: 900, v: 1000),
        HSVColor(h: 38, s: 850, v: 1000),
        HSVColor(h: 120, s: 850, v: 850),
        HSVColor(h: 205, s: 900, v: 1000),
        HSVColor(h: 278, s: 760, v: 950)
    ]

    init(color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .white
        let hue = Int(round(nsColor.hueComponent * 360.0))
        let saturation = Int(round(nsColor.saturationComponent * 1000.0))
        self.init(h: hue, s: saturation, v: HSVColor.defaultColorValue)
    }
}

extension Color {
    init(hsv: HSVColor) {
        self.init(
            hue: Double(hsv.h) / 360.0,
            saturation: Double(hsv.s) / 1000.0,
            brightness: Double(hsv.v) / 1000.0
        )
    }
}

private struct ColorSwatch: View {
    let color: HSVColor
    var size: CGFloat = 24

    var body: some View {
        Circle()
            .fill(Color(hsv: color))
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 2)
    }
}

private struct ColorSpectrumPicker: View {
    @Binding var color: HSVColor
    var onCommit: ((HSVColor) -> Void)? = nil

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let x = CGFloat(color.h) / 360.0 * size.width
            let y = CGFloat(color.s) / 1000.0 * size.height

            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        .red,
                        .yellow,
                        .green,
                        .cyan,
                        .blue,
                        .purple,
                        .red
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .overlay(
                    LinearGradient(
                        colors: [.white, .white.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )

                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .background(Circle().fill(Color(hsv: color)))
                    .frame(width: 18, height: 18)
                    .shadow(color: Color.black.opacity(0.22), radius: 5, x: 0, y: 2)
                    .offset(x: min(max(0, x), size.width) - 9, y: min(max(0, y), size.height) - 9)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        color = color(at: value.location, in: size)
                    }
                    .onEnded { value in
                        let finalColor = color(at: value.location, in: size)
                        color = finalColor
                        onCommit?(finalColor)
                    }
            )
        }
    }

    private func color(at point: CGPoint, in size: CGSize) -> HSVColor {
        guard size.width > 0, size.height > 0 else { return color }
        let clampedX = min(max(0, point.x), size.width)
        let clampedY = min(max(0, point.y), size.height)
        return HSVColor(
            h: Int(round(clampedX / size.width * 360.0)),
            s: Int(round(clampedY / size.height * 1000.0)),
            v: HSVColor.defaultColorValue
        )
    }
}
