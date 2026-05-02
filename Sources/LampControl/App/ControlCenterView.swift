import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject private var appState: AppState

    private let ink = LCTheme.ink
    private let muted = LCTheme.muted
    private let accent = LCTheme.accent

    var body: some View {
        ZStack {
            background

            if #available(macOS 26.0, *) {
                GlassEffectContainer(spacing: 16) {
                    content
                }
            } else {
                content
            }

            if appState.isOnboardingPresented {
                OnboardingOverlay()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .frame(width: appState.preferredPopoverSize.width, height: appState.preferredPopoverSize.height)
        .foregroundStyle(ink)
    }

    private var content: some View {
        VStack(spacing: 12) {
            header
            tabs

            if !appState.message.isEmpty {
                messageView
            }

            switch appState.selectedTab {
            case .lamps:
                LampsView()
            case .settings:
                SettingsView()
            }
        }
        .padding(16)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    LCTheme.backgroundTop,
                    LCTheme.backgroundMiddle,
                    LCTheme.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    LCTheme.glassHighlight,
                    Color.clear,
                    LCTheme.backgroundShade
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    LCTheme.sideHighlight,
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            Rectangle()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.18))
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Image(systemName: "lightbulb.led")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 42, height: 42)
            .liquidGlassSurface(radius: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text("LampControl")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ink)
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(appState.canSync ? Color.blue.opacity(0.70) : Color.gray.opacity(0.45))
                            .frame(width: 6, height: 6)
                        if appState.canSync {
                            Circle()
                                .stroke(Color.blue.opacity(0.40), lineWidth: 1.5)
                                .frame(width: 6, height: 6)
                                .scaleEffect(appState.isAutoSyncing ? 2.0 : 1.0)
                                .opacity(appState.isAutoSyncing ? 0 : 0.6)
                                .animation(appState.isAutoSyncing ? .easeOut(duration: 1.0).repeatForever(autoreverses: false) : .default, value: appState.isAutoSyncing)
                        }
                    }
                    Text(appState.canSync ? "cloud.active" : "config.required")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(muted)
                }
            }
            Spacer()

            Button(action: appState.quit) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(muted)
                    .frame(width: 34, height: 34)
            }
            .liquidGlassButtonStyle()
            .help("app.quit")
        }
    }

    private var tabs: some View {
        HStack(spacing: 6) {
            tabButton(.lamps, title: "tab.lamps", icon: "slider.horizontal.3")
            tabButton(.settings, title: "tab.settings", icon: "gearshape")
        }
        .padding(4)
        .liquidGlassSurface(radius: 18)
    }

    private func tabButton(_ tab: ControlTab, title: LocalizedStringKey, icon: String) -> some View {
        let isActive = appState.selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                appState.selectedTab = tab
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : muted)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .liquidGlassSurface(
                    radius: 16,
                    tint: isActive ? accent.opacity(0.58) : Color.clear,
                    interactive: true
                )
                .overlay(alignment: .bottom) {
                    if isActive {
                        Capsule()
                            .fill(accent.opacity(0.85))
                            .frame(width: 28, height: 2)
                            .padding(.bottom, 5)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var isErrorMessage: Bool {
        let lowered = appState.message.lowercased()
        return lowered.contains("error") || lowered.contains("erreur") ||
               lowered.contains("impossible") || lowered.contains("failed") ||
               lowered.contains("invalide") || lowered.contains("invalid") ||
               lowered.contains("échec") || lowered.contains("failed")
    }

    private var messageView: some View {
        HStack(spacing: 8) {
            if isErrorMessage {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LCTheme.error)
            } else {
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text(appState.message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ink)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .liquidGlassSurface(radius: 15, tint: isErrorMessage ? LCTheme.errorSurface : LCTheme.infoSurface)
    }

}

extension View {
    @ViewBuilder
    func liquidGlassSurface(radius: CGFloat, tint: Color? = nil, interactive: Bool = false) -> some View {
        self.fallbackGlassSurface(radius: radius, tint: tint)
    }

    @ViewBuilder
    func liquidGlassCircle(tint: Color? = nil, interactive: Bool = false) -> some View {
        self.fallbackGlassSurface(radius: 999, tint: tint)
    }

    private func fallbackGlassSurface(radius: CGFloat, tint: Color?) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [
                        LCTheme.surfaceTop,
                        (tint ?? LCTheme.surfaceMiddle).opacity(0.22),
                        LCTheme.surfaceBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LCTheme.strokeMiddle,
                        lineWidth: 0.8
                    )
            )
    }

    @ViewBuilder
    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        self
            .buttonStyle(.plain)
            .fallbackGlassSurface(
                radius: prominent ? 18 : 13,
                tint: prominent ? LCTheme.accent.opacity(0.35) : Color.white.opacity(0.08)
            )
    }
}

enum LCTheme {
    static let ink = Color.primary
    static let muted = Color.secondary
    static let accent = Color(nsColor: .controlAccentColor)
    static let softAccent = Color(nsColor: .separatorColor)

    static let backgroundTop = Color(nsColor: .windowBackgroundColor).opacity(0.96)
    static let backgroundMiddle = Color(nsColor: .controlBackgroundColor).opacity(0.90)
    static let backgroundBottom = Color(nsColor: .underPageBackgroundColor).opacity(0.92)
    static let glassHighlight = Color(nsColor: .highlightColor).opacity(0.26)
    static let sideHighlight = Color(nsColor: .highlightColor).opacity(0.18)
    static let backgroundShade = Color.black.opacity(0.05)

    static let surfaceTop = Color(nsColor: .controlBackgroundColor).opacity(0.72)
    static let surfaceMiddle = Color(nsColor: .windowBackgroundColor)
    static let surfaceBottom = Color(nsColor: .separatorColor).opacity(0.08)
    static let strokeTop = Color(nsColor: .highlightColor).opacity(0.62)
    static let strokeMiddle = Color(nsColor: .separatorColor).opacity(0.26)
    static let strokeBottom = Color.black.opacity(0.06)
    static let overlayScrim = Color.black.opacity(0.28)

    static let success = Color.green.opacity(0.80)
    static let error = Color.red.opacity(0.80)
    static let errorSurface = Color.red.opacity(0.10)
    static let infoSurface = Color.blue.opacity(0.08)
}
